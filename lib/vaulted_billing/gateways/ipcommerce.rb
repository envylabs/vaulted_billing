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
        UnavailableKeyError = Class.new(VaultedBilling::CredentialError)
        
        attr_reader :identity_token

        def initialize(identity_token)
          @identity_token = identity_token
          @expires_at = nil
        end

        def key
          renew! unless valid?
          read_key || raise(UnavailableKeyError, 'A service key could not be retrieved for this session.')
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

        def before_request(request)
          request.delete "accept"
        end

        def renew!
          response = http.get
          raise(UnavailableKeyError, 'Unable to renew service keys.') unless response.success?
          @expires_at = Time.now + 30.minutes
          @key = response.body.try(:[], 1...-1)
        end
        
        private
        def http
          @request ||= begin
            urls = ["https://cws-01.cert.ipcommerce.com/REST/2.0.15/SvcInfo/token",
                    "https://cws-02.cert.ipcommerce.com/REST/2.0.15/SvcInfo/token"]
            VaultedBilling::HTTP.new(self, urls, {
              :headers => {'Content-Type' => 'application/json'},
              :before_request => :before_request,
              :basic_auth => [@identity_token, ""]
            })
          end
        end
      end

      attr_reader :service_key_store

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
      def add_customer_credit_card(customer, credit_card, options = {})
        credit_card = credit_card.to_vaulted_billing

        authorization = authorize(customer, credit_card, 1.00, options)
        void(authorization.id, options) if authorization.success?

        respond_with(credit_card, authorization.response, :success => authorization.success?) do |cc|
          cc.vault_id = authorization.response.body['PaymentAccountDataToken'].presence
        end
      end

      def authorize(customer, credit_card, amount, options = {})
        data = {
          "__type" => "AuthorizeTransaction:http://schemas.ipcommerce.com/CWS/v2.0/Transactions/Rest",
          :ApplicationProfileId => @application_id,
          :MerchantProfileId => options[:merchant_profile_id],
          :Transaction => {
            :"__type" => "BankcardTransaction:http://schemas.ipcommerce.com/CWS/v2.0/Transactions/Bankcard",
            :TransactionData => {
              :Amount => "%.2f" % amount,
              :CurrencyCode => 4,
              :TransactionDateTime => Time.now.xmlschema,
              :CustomerPresent => 0,
              :EntryMode => 1,
              :GoodsType => 0,
              :IndustryType => 2,
              :SignatureCaptured => false,
              :OrderNumber => options[:order_id] || generate_order_number
            },
            :TenderData => {
              :CardData => {
                :CardholderName => nil,
                :CardType => self.class.credit_card_type_id(credit_card.card_number),
                :Expire => credit_card.expires_on.try(:strftime, "%m%y"),
                :PAN => credit_card.card_number
              }
            }
          }
        }
        
        response = http(options[:workflow_id] || @service_id).post(data)
        transaction = new_transaction_from_response(response) 
        respond_with(transaction,
                     response,
                     :success => (transaction.code == 1))
      end

      def capture(transaction_id, amount, options = {})
        data = {
          :"__type" => "Capture:http://schemas.ipcommerce.com/CWS/v2.0/Transactions/Rest",
          :ApplicationProfileId => @application_id,
          :DifferenceData => {
            :"__type" => "BankcardCapture:http://schemas.ipcommerce.com/CWS/v2.0/Transactions/Bankcard",
            :TransactionId => transaction_id,
            :Addendum => nil,
            :Amount => "%.2f" % amount
          }
        }
        
        response = http(options[:workflow_id] || @service_id, transaction_id).put(data)
        transaction = new_transaction_from_response(response)
        respond_with(transaction,
                     response,
                     :success => (transaction.code == 1))
      end

      def purchase(customer, credit_card, amount, options = {})
        data = {
          "__type" => "AuthorizeAndCaptureTransaction:http://schemas.ipcommerce.com/CWS/v2.0/Transactions/Rest",
          :ApplicationProfileId => @application_id,
          :MerchantProfileId => options[:merchant_profile_id],
          :Transaction => {
            :"__type" => "BankcardTransaction:http://schemas.ipcommerce.com/CWS/v2.0/Transactions/Bankcard",
            :TransactionData => {
              :Amount => "%.2f" % amount,
              :CurrencyCode => 4,
              :TransactionDateTime => Time.now.xmlschema,
              :CustomerPresent => 0,
              :EmployeeId => options[:employee_id],
              :EntryMode => 1,
              :GoodsType => 0,
              :IndustryType => 2,
              :OrderNumber => options[:order_id] || generate_order_number,
              :SignatureCaptured => false
            },
            :TenderData => {
              :CardData => {
                :CardholderName => nil,
                :CardType => self.class.credit_card_type_id(credit_card.card_number),
                :Expire => credit_card.expires_on.try(:strftime, "%m%y"),
                :PAN => credit_card.card_number
              }
            }
          }
        }
        response = http(options[:workflow_id] || @service_id).post(data)
        transaction = new_transaction_from_response(response)
        respond_with(transaction,
                     response,
                     :success => (transaction.code == 1))
      end

      def refund(transaction_id, amount, options = {})
        data = {
          :"__type" => "ReturnById:http://schemas.ipcommerce.com/CWS/v2.0/Transactions/Rest",
          :ApplicationProfileId => @application_id,
          :MerchantProfileId => options[:merchant_profile_id],
          :DifferenceData => {
            :"__type" => "BankcardReturn:http://schemas.ipcommerce.com/CWS/v2.0/Transactions/Bankcard",
            :TransactionId => transaction_id,
            :Addendum => nil,
            :Amount => "%.2f" % amount
          }
        }
        
        response = http(options[:workflow_id] || @service_id).post(data)
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
      def update_customer_credit_card(customer, credit_card, options = {})
        add_customer_credit_card(customer, credit_card, options)
      end
    
      def void(transaction_id, options = {})
        data = {
          :"__type" => "Undo:http://schemas.ipcommerce.com/CWS/v2.0/Transactions/Rest",
          :ApplicationProfileId => @application_id,
          :DifferenceData => {
            :"__type" => "BankcardUndo:http://schemas.ipcommerce.com/CWS/v2.0/Transactions/Bankcard",
            :TransactionId => transaction_id,
            :Addendum => nil
          }
        }

        response = http(options[:workflow_id] || @service_id, transaction_id).put(data)
        transaction = new_transaction_from_response(response)
        respond_with(transaction,
                     response,
                     :success => (transaction.code == 1))
      end


      private


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


      def generate_order_number
        (Time.now.to_f * 100000).to_i.to_s(36) + rand(60000000).to_s(36)
      end

      def http(*params)
        urls = %W(
          https://cws-01.cert.ipcommerce.com/REST/2.0.15/Txn/#{params.join('/')}
          https://cws-02.cert.ipcommerce.com/REST/2.0.15/Txn/#{params.join('/')}
        )
        VaultedBilling::HTTP.new(self, urls, {
          :headers => { 'Content-Type' => 'application/json' },
          :before_request => :before_request,
          :basic_auth => [@service_key_store.key, ""],
          :on_success => :on_success
        })
      end
      
      def before_request(request)
        request.body = MultiJson.encode(request.body)
        # request.delete "accept"
      end
      
      def on_success(response)
        response.body = decode_body(response.body) || {}
        response.success = [1, 2].include?(response.body['Status'])
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
          if errors = parse_validation_errors(response)
            Transaction.new({
              :message => errors.join("\n"),
              :code => (response.body['ErrorResponse'] || {})['ErrorId']
            })
          else
            Transaction.new({
              :message => response.body ? (response.body['ErrorResponse'] || {})['Reason'] : nil,
              :code => response.body ? (response.body['ErrorResponse'] || {})['ErrorId'] : nil
            })
          end
        end
      end
      
      def parse_validation_errors(response)
        errors = ChainableHash.new.merge(response.body || {})
        if errors['ErrorResponse']['ValidationErrors'].present?
          [errors['ErrorResponse']['ValidationErrors']['ValidationError']].flatten.collect { |e| e['RuleMessage'] }
        end
      end
      
      def parse_error(response_body)
        MultiXml.parse(response_body)
      rescue MultiXml::ParseError
      end
      
      def respond_with(object, response = nil, options = {}, &block)
        super(object, options, &block).tap do |o|
          if response
            o.response = response
            o.raw_response = response.raw_response.try(:body)
            o.connection_error = response.connection_error
          end
        end
      end
    end    
  end
end