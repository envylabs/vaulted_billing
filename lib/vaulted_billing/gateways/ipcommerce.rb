require 'multi_json'
require 'multi_xml'
require 'net/http'

module VaultedBilling
  module Gateways
    ##
    # Interface to IPCommerce.
    #
    # == Example
    #
    #   VaultedBilling::Gateways::IPCommerce.new(:username => 'identity-token', :service_key_store => XXX).tap do |ipc|
    #     customer = ipc.add_customer(Customer.new)
    #     credit_card = ipc.add_credit_card(customer, CreditCard.new)
    #     ipc.purchase(customer, credit_card, 10.00)
    #   end
    #
    class Ipcommerce
      include VaultedBilling::Gateway

      Companies = {
        2 => /^4\d{12}(\d{3})?$/, # Visa
        3 => /^(5[1-5]\d{4}|677189)\d{10}$/, # MasterCard
        4 => /^3[47]\d{13}$/, # American Express
        5 => /^3(0[0-5]|[68]\d)\d{11}$/, # Diners Club
        6 => /^(6011|65\d{2}|64[4-9]\d)\d{12}|(62\d{14})$/, # Discover
        7 => /^35(28|29|[3-8]\d)\d{12}$/ # JCB
      }.freeze

      class ServiceKeyStore
        attr_reader :identity_token

        def initialize(identity_token)
          @identity_token = identity_token
          @expires_at = nil
        end

        def key
          renew! unless valid?
          read_key
        end

        def read_key
          @key
        end

        def store_key(key)
          @key = key
        end

        def valid?
          @expires_at && (@expires_at > Time.now + 5.minutes)
        end

        def renew!
          # contact ipcommerce sign on for new keys.
          uri = URI.parse("https://cws-01.cert.ipcommerce.com/REST/2.0.15/SvcInfo/token")
          request = Net::HTTP::Get.new(uri.path)
          
          request.initialize_http_header({
            'User-Agent' => "vaulted_billing/#{VaultedBilling::Version}"
          })
          request.set_content_type "application/json"
          request.delete "accept"
          request.basic_auth(@identity_token, "")
          response = Net::HTTP.new(uri.host, uri.port).tap do |https|
            https.use_ssl = true
            https.ca_file = VaultedBilling.config.ca_file
            https.verify_mode = OpenSSL::SSL::VERIFY_PEER
          end
          result = response.request(request)
          body = result.body
          
          @key = body[1, body.length-2]

          @expires_at = Time.now + 30.minutes
          @key
          return result, body
        end
      end


      def initialize(options = {})
        @identity_token = options[:username] || VaultedBilling.config.ipcommerce.username
        @raw_options = options[:raw_options] || VaultedBilling.config.ipcommerce.raw_options
        @test_mode = options.has_key?(:test) ? options[:test] : (VaultedBilling.config.ipcommerce.test_mode || VaultedBilling.config.test_mode)
        @application_id = options[:application_id] || @raw_options["application_id"]
        @service_id = options[:service_id] || @raw_options["service_id"]
        @service_key_store = options[:service_key_store] || ServiceKeyStore.new(@identity_token)
      end


      ##
      # A stub, since the IP Commerce only generates tokens during
      # successful authorization transactions.
      #
      def add_customer(customer)
        respond_with customer.to_vaulted_billing
      end

      ##
      # A stub, since the IP Commerce only generates tokens during
      # successful authorization transactions.
      #
      #--
      # TODO: If necessary, this may be implemented by Authorizing the given card for $1.00, then voiding immediately.
      #++
      # 
      def add_customer_credit_card(customer, credit_card)
        respond_with credit_card.to_vaulted_billing
      end

      def authorize(customer, credit_card, amount, options = {})
        data = {
          "__type" => "AuthorizeTransaction:http://schemas.ipcommerce.com/CWS/v2.0/Transactions/Rest",
          ApplicationProfileId: @application_id,
          MerchantProfileId: options[:merchant_profile_id],
          Transaction: {
            "__type" => "BankcardTransaction:http://schemas.ipcommerce.com/CWS/v2.0/Transactions/Bankcard",
            TransactionData: {
              Amount: "%.2f" % amount,
              CurrencyCode: 4,
              TransactionDateTime: Time.now.xmlschema,
              CustomerPresent: 0,
              EntryMode: 1,
              GoodsType: 0,
              IndustryType: 2,
              SignatureCaptured: false,
              OrderNumber: options[:order_id] || generate_order_number
            },
            TenderData: {
              CardData: {
                CardholderName: nil,
                CardType: self.class.credit_card_type_id(credit_card.card_number),
                Expire: credit_card.expires_on.try(:strftime, "%m%y"),
                PAN: credit_card.card_number
              }
            }
          }
        }
        
        response = post("Txn/#{options[:workflow_id] || @service_id}", data)
        transaction = new_transaction_from_response(response) 
        respond_with(transaction,
                     response,
                     :success => (transaction.code == 1))
      end


      def capture(transaction_id, amount, options = {})
        data = {
          "__type" => "Capture:http://schemas.ipcommerce.com/CWS/v2.0/Transactions/Rest",
          ApplicationProfileId: @application_id,
          DifferenceData: {
            "__type" => "BankcardCapture:http://schemas.ipcommerce.com/CWS/v2.0/Transactions/Bankcard",
            TransactionId: transaction_id,
            Addendum: nil,
            Amount: "%.2f" % amount
          }
        }
        
        response = put("Txn/#{options[:workflow_id] || @service_id}/#{transaction_id}", data)
        transaction = new_transaction_from_response(response)
        respond_with(transaction,
                     response,
                     :success => (transaction.code == 1))
      end

      def purchase(customer, credit_card, amount, options = {})
        data = {
          "__type" => "AuthorizeAndCaptureTransaction:http://schemas.ipcommerce.com/CWS/v2.0/Transactions/Rest",
          ApplicationProfileId: @application_id,
          MerchantProfileId: options[:merchant_profile_id],
          Transaction: {
            "__type" => "BankcardTransaction:http://schemas.ipcommerce.com/CWS/v2.0/Transactions/Bankcard",
            TransactionData: {
              Amount: "%.2f" % amount,
              CurrencyCode: 4,
              TransactionDateTime: Time.now.xmlschema,
              CustomerPresent: 0,
              EmployeeId: options[:employee_id],
              EntryMode: 1,
              GoodsType: 0,
              IndustryType: 2,
              OrderNumber: options[:order_id] || generate_order_number,
              SignatureCaptured: false
            },
            TenderData: {
              CardData: {
                CardholderName: nil,
                CardType: self.class.credit_card_type_id(credit_card.card_number),
                Expire: credit_card.expires_on.try(:strftime, "%m%y"),
                PAN: credit_card.card_number
              }
            }
          }
        }
        response = post("Txn/#{options[:workflow_id] || @service_id}", data)
        transaction = new_transaction_from_response(response)
        respond_with(transaction,
                     response,
                     :success => (transaction.code == 1))
      end

      def refund(transaction_id, amount, options = {})
        data = {
          "__type" => "ReturnById:http://schemas.ipcommerce.com/CWS/v2.0/Transactions/Rest",
          ApplicationProfileId: @application_id,
          MerchantProfileId: options[:merchant_profile_id],
          DifferenceData: {
            "__type" => "BankcardReturn:http://schemas.ipcommerce.com/CWS/v2.0/Transactions/Bankcard",
            TransactionId: transaction_id,
            Addendum: nil,
            Amount: "%.2f" % amount
          }
        }
        
        response = post("Txn/#{options[:workflow_id] || @service_id}", data)
        transaction = new_transaction_from_response(response)
        respond_with(transaction,
                     response,
                     :success => (transaction.code == 1))
      end
      
      ##
      # A stub, since the IP Commerce only generates tokens during
      # successful authorization transactions.
      #
      def remove_customer(customer)
        respond_with customer.to_vaulted_billing
      end

      ##
      # A stub, since the IP Commerce only generates tokens during
      # successful authorization transactions.
      #
      def remove_customer_credit_card(customer, credit_card)
        respond_with credit_card.to_vaulted_billing
      end

      ##
      # A stub, since the IP Commerce only generates tokens during
      # successful authorization transactions.
      #
      def update_customer(customer)
        respond_with customer.to_vaulted_billing
      end

      ##
      # A stub, since the IP Commerce only generates tokens during
      # successful authorization transactions.
      #
      def update_customer_credit_card(customer, credit_card)
        respond_with credit_card.to_vaulted_billing
      end
    
      def void(transaction_id, options = {})
        data = {
          "__type" => "Undo:http://schemas.ipcommerce.com/CWS/v2.0/Transactions/Rest",
          ApplicationProfileId: @application_id,
          DifferenceData: {
            "__type" => "BankcardUndo:http://schemas.ipcommerce.com/CWS/v2.0/Transactions/Bankcard",
            TransactionId: transaction_id,
            Addendum: nil
          }
        }

        response = put("Txn/#{options[:workflow_id] || @service_id}/#{transaction_id}", data)
        transaction = new_transaction_from_response(response)
        respond_with(transaction,
                     response,
                     :success => (transaction.code == 1))
      end


      ##
      # Returns the name of the card company based on the given number, or
      # nil if it is unrecognized.
      #
      # This was heavily lifted from ActiveMerchant.
      #
      def self.credit_card_type_id(number)
        Companies.each do |company, pattern|
          return company if number =~ pattern
        end
        return 1
      end
      
      private

      def generate_order_number
        (Time.now.to_f * 100000).to_i.to_s(36) + rand(60000000).to_s(36)
      end

      def post(path, data = {})
        uri = uri_for(path)
        request(uri, Net::HTTP::Post.new(uri.path), data)
      end
      
      def get(path, data = {})
        uri = uri_for(path)
        request(uri, Net::HTTP::Get.new(uri.path), data)
      end

      def put(path, data = {})
        uri = uri_for(path)
        request(uri, Net::HTTP::Put.new(uri.path), data)
      end

      def uri_for(path)
        URI.parse("https://cws-01.cert.ipcommerce.com/REST/2.0.15/#{path}")
      end
  
      def request(uri, request, data)
        encoded_data = MultiJson.encode(data)
        request.initialize_http_header({
          'User-Agent' => "vaulted_billing/#{VaultedBilling::Version}"
        })
        request.body = encoded_data if encoded_data
        request.basic_auth(@service_key_store.key, "")
        request.set_content_type "application/json"
        request.delete "accept"
        response = Net::HTTP.new(uri.host, uri.port).tap do |https|
          https.use_ssl = true
          https.ca_file = VaultedBilling.config.ca_file
          https.verify_mode = OpenSSL::SSL::VERIFY_PEER
        end
        
        begin
          VaultedBilling::HttpsInterface::PostResponse.new(response.request(request)).tap do |post_response|
            after_request_on_success(post_response)
          end
        rescue *VaultedBilling::HttpsInterface::HTTP_ERRORS
          VaultedBilling::HttpsInterface::PostResponse.new(nil).tap do |post_response|
            post_response.success = false
            post_response.message = "%s - %s" % [$!.class.name, $!.message]
            post_response.connection_error = true
            after_request_on_exception(post_response, $!)
          end
        end
      end
      
      def after_request_on_success(response)
        response.body = decode_body(response.body) || {}
        response.success = [1, 2].include?(response.body['Status'])
      end
      
      def after_request_on_exception(response)
      end
      
      def decode_body(string)
        MultiJson.decode(string)
      rescue MultiJson::DecodeError
        parse_error(string)
      end
      
      def new_transaction_from_response(response)
        if response.success?
          Transaction.new({
            :id => response.body['TransactionId'],
            :avs_response => response.body['AVSResult'] == 1,
            :cvv_response => response.body['CVResult'] == 1,
            :authcode => response.body['ApprovalCode'],
            :message => response.body['StatusMessage'],
            :code => response.body['Status'],
            :masked_card_number => response.body['MaskedPAN']
          })
        else
          Transaction.new({
            :message => (response.body['ErrorResponse'] || {})['Reason'],
            :code => (response.body['ErrorResponse'] || {})['ErrorId']
          })
        end
      end
      
      def parse_error(response_body)
        MultiXml.parse(response_body)
      rescue MultiXml::ParseError
      end
      
      def respond_with(object, response = nil, options = {}, &block)
        super(object, options, &block).tap do |o|
          if response
            o.raw_response = response.raw_response.body
            o.connection_error = response.connection_error
          end
        end
      end
    end    
  end
end
