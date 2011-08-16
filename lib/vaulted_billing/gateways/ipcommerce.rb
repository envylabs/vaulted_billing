require 'multi_json'
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
      include VaultedBilling::HttpsInterface
      attr_accessor :service_key_store

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
              TransactionDateTime: Time.now.strftime("%Y-%m-%dT%H:%M:%S.%L+00:00"),
              CustomerPresent: 0,
              EmployeeId: options[:employee_id],
              EntryMode: 1,
              GoodsType: 0,
              IndustryType: 0,
              OrderNumber: options[:order_id],
              SignatureCaptured: false
            },
            TenderData: {
              CardData: {
                CardholderName: nil,
                CardType: options[:card_type_id],
                Expire: credit_card.expires_on.try(:strftime, "%m%y"),
                PAN: credit_card.card_number
              }
            }
          }
        }
        
        response = post("Txn/#{options[:workflow_id]}", data)
        transaction = new_transaction_from_response(response.body) 
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
            Addendum: nil
          }
        }
        
        response = put("Txn/#{options[:workflow_id]}/#{transaction_id}", data)
        transaction = new_transaction_from_response(response.body) 
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
              TransactionDateTime: Time.now.strftime("%Y-%m-%dT%H:%M:%S.%L+00:00"),
              CustomerPresent: 0,
              EmployeeId: options[:employee_id],
              EntryMode: 1,
              GoodsType: 0,
              IndustryType: 0,
              OrderNumber: options[:order_id],
              SignatureCaptured: false
            },
            TenderData: {
              CardData: {
                CardholderName: nil,
                CardType: options[:card_type_id],
                Expire: credit_card.expires_on.try(:strftime, "%m%y"),
                PAN: credit_card.card_number
              }
            }
          }
        }
        response = post("Txn/#{options[:workflow_id]}", data)
        transaction = new_transaction_from_response(response.body) 
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
            Addendum: nil
          }
        }
        
        response = post("Txn/#{options[:workflow_id]}", data)
        transaction = new_transaction_from_response(response.body) 
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
            Addendum: nil,
            # PINDebitReason: options[:reason],
            TenderData: {
              CardData: {
                CardholderName: nil,
                CardType: 'Visa',
                Expire: options[:credit_card].expires_on.try(:strftime, "%m%y"),
                PAN: options[:credit_card].card_number
              }
            }
          }
        }

        response = put("Txn/#{options[:workflow_id]}/#{transaction_id}", data)
        transaction = new_transaction_from_response(response.body) 
        respond_with(transaction,
                     response,
                     :success => (transaction.code == 1))
      end

      private

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

      def delete(path, data = {})
        uri = uri_for(path)
        request(uri, Net::HTTP::Delete.new(uri.path), data)
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
          PostResponse.new(response.request(request)).tap do |post_response|
            after_post_caller(post_response)
            after_post_on_success(post_response)
          end
        rescue *HTTP_ERRORS
          PostResponse.new(nil).tap do |post_response|
            post_response.success = false
            post_response.message = "%s - %s" % [$!.class.name, $!.message]
            post_response.connection_error = true
            after_post_caller(post_response)
            after_post_on_exception(post_response, $!)
          end
        end
      end
      
      def new_transaction_from_response(response)
        decoded_data = MultiJson.decode(response)
        Transaction.new({
          :id => decoded_data['TransactionId'],
          :avs_response => decoded_data['AVSResult'] == 1,
          :cvv_response => decoded_data['CVResult'] == 1,
          :authcode => decoded_data['ApprovalCode'],
          :message => decoded_data['StatusMessage'],
          :code => decoded_data['Status'].to_i,
          :masked_card_number => decoded_data['MaskedPAN']
        })
      rescue MultiJson::DecodeError
        Transaction.new({ :code => 2 })
      end
      
      def respond_with(object, response = nil, options = {}, &block)
        super(object, options, &block).tap do |o|
          if response
            o.raw_response = response.raw_response.try(:body)
            o.connection_error = response.connection_error
            o.response_message = (response.body || {})['StatusMessage']
            unless response.success?
              o.error_code = (response.body || {})['StatusCode']
            end
          end
        end
      end
    end    
  end
end
