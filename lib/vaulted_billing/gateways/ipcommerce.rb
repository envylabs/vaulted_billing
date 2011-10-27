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
      
      AvsResults = [
        "Not Set", "Not Included", "Match", "No Match", "Issuer Not Certified",
        "No Response From Card Association", "Unknown Response From Card Association", "Not Verified", "Bad Format"
      ]

      Countries = %w(
        !! AF AX AL DZ AS AD AO AI AQ
        AG AR AM AW AU AT AZ BS BH BD
        BB BY BE BZ BJ BM BT BO BA BW
        BV BR IO BN BG BF BI KH CM CA
        CV KY CF TD CL CN CX CC CO KM
        CG CD CK CR CI HR CU CY CZ DK
        DJ DM DO EC EG SV GQ ER EE ET
        FK FO FJ FI FR FX GF PF TF GA
        GM GE DE GH GI GR GL GD GP GU
        GT GG GN GW GY HT HM VA HN HK
        HU IS IN ID IR IQ IE IM IL IT
        JM JP JE JO KZ KE KI KP KR KW
        KG LA LV LB LS LR LY LI LT LU
        MO MK MG MW MY MV ML MT MH MQ
        MR MU YT MX FM MD MC MN ME MS
        MA MZ MM NA NR NP NL AN NC NZ
        NI NE NG NU NF MP NO OM PK PW
        PS PA PG PY PE PH PN PL PT PR
        QA RE RO RU RW SH KN LC PM VC
        WS SM ST SA SN RS CS SC SL SG
        SK SI SB SO ZA GS ES LK SD SR
        SJ SZ SE CH SY TW TJ TZ TH TL
        TG TK TP TO TT TN TR TM TC TV
        UG UA AE GB US UM UY UZ VU VE
        VN VG VI WF EH YE YU ZM ZW
      ).freeze
       
      Companies = {
        2 => /^4\d{12}(\d{3})?$/, # Visa
        3 => /^(5[1-5]\d{4}|677189)\d{10}$/, # MasterCard
        4 => /^3[47]\d{13}$/, # American Express
        5 => /^3(0[0-5]|[68]\d)\d{11}$/, # Diners Club
        6 => /^(6011|65\d{2}|64[4-9]\d)\d{12}|(62\d{14})$/, # Discover
        7 => /^35(28|29|[3-8]\d)\d{12}$/ # JCB
      }.freeze

      CVResults = [
        "Not Set", "Match", "No Match", "Not Processed", "Not Included",
        "No Code Present", "Should Have Been Present", "Issuer Not Certified", "Invalid", "No Response",
        "Not Applicable"
      ].freeze
      
      Endpoints = [
        "https://cws-01.ipcommerce.com/REST/2.0.15/",
        "https://cws-02.ipcommerce.com/REST/2.0.15/"
      ].freeze
      
      TestEndpoints = [
        "https://cws-01.cert.ipcommerce.com/REST/2.0.15/",
        "https://cws-02.cert.ipcommerce.com/REST/2.0.15/"
      ].freeze

      class ServiceKeyStore
        UnavailableKeyError = Class.new(VaultedBilling::CredentialError)

        attr_reader :identity_token

        def initialize(identity_token, test_mode = false)
          @identity_token = identity_token
          @expires_at = nil
          @test_mode = test_mode
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
          store_key(response.body.try(:[], 1...-1))
        end

        private
        def http
          @request ||= begin
            VaultedBilling::HTTP.new(self, urls, {
              :headers => {'Content-Type' => 'application/json'},
              :before_request => :before_request,
              :basic_auth => [@identity_token, ""]
            })
          end
        end
        
        def urls
          endpoints.collect do |url|
            url + "SvcInfo/token"
          end
        end
        
        def endpoints
          @test_mode ? TestEndpoints : Endpoints
        end
      end

      attr_reader :service_key_store

      def initialize(options = {})
        @identity_token = options[:username] || VaultedBilling.config.ipcommerce.username
        @raw_options = options[:raw_options] || VaultedBilling.config.ipcommerce.raw_options
        @test_mode = options.has_key?(:test) ? options[:test] : (VaultedBilling.config.ipcommerce.test_mode || VaultedBilling.config.test_mode)
        @application_id = options[:application_id] || @raw_options["application_id"]
        @service_id = options[:service_id] || @raw_options["service_id"]
        @service_key_store = options[:service_key_store] || ServiceKeyStore.new(@identity_token, @test_mode)
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
        void = void(authorization.id, options) if authorization.success?

        respond_with(credit_card, authorization.response, { 
            :success => authorization.success?, 
            :transactions => { :void => void, :authorization => authorization }
        }) do |cc|
          cc.vault_id = authorization.response.body['PaymentAccountDataToken'].presence
        end
      end

      def authorize(customer, credit_card, amount, options = {})
        credit_card = credit_card.to_vaulted_billing
        data = {
          "__type" => "AuthorizeTransaction:http://schemas.ipcommerce.com/CWS/v2.0/Transactions/Rest",
          :ApplicationProfileId => @application_id,
          :MerchantProfileId => options[:merchant_profile_id],
          :Transaction => {
            :"__type" => "BankcardTransaction:http://schemas.ipcommerce.com/CWS/v2.0/Transactions/Bankcard",
            :TransactionData => {
              :Amount => "%.2f" % amount,
              :ApprovalCode => options[:approval_code],
              :CurrencyCode => 4,
              :TransactionDateTime => Time.now.xmlschema,
              :CustomerPresent => options[:customer_present] || 0, # Not Set
              :EntryMode => options[:entry_mode] || 1, # Keyed
              :GoodsType => options[:goods_type] || 0, # Not Set
              :IndustryType => options[:industry_type] || 2, # Ecommerce
              :SignatureCaptured => options[:signature_captured] || false,
              :OrderNumber => options[:order_id] || generate_order_number,
              :EmployeeId => options[:employee_id]
            },
            :TenderData => card_data(credit_card)
          }
        }

        response = http("Txn", options[:workflow_id] || @service_id).post(data)
        transaction = new_transaction_from_response(response)
        respond_with(transaction,
                     response,
                     :success => valid_code?(transaction.code))
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

        response = http("Txn", options[:workflow_id] || @service_id, transaction_id).put(data)
        transaction = new_transaction_from_response(response)
        respond_with(transaction,
                     response,
                     :success => valid_code?(transaction.code))
      end

      def purchase(customer, credit_card, amount, options = {})
        credit_card = credit_card.try(:to_vaulted_billing)
        data = {
          "__type" => "AuthorizeAndCaptureTransaction:http://schemas.ipcommerce.com/CWS/v2.0/Transactions/Rest",
          :ApplicationProfileId => @application_id,
          :MerchantProfileId => options[:merchant_profile_id],
          :Transaction => {
            :"__type" => "BankcardTransaction:http://schemas.ipcommerce.com/CWS/v2.0/Transactions/Bankcard",
            :TransactionData => {
              :Amount => "%.2f" % amount,
              :ApprovalCode => options[:approval_code],
              :CurrencyCode => 4,
              :TransactionDateTime => Time.now.xmlschema,
              :CustomerPresent => options[:customer_present] || 0, # Not Set
              :EmployeeId => options[:employee_id],
              :EntryMode => options[:entry_mode] || 1, # Keyed
              :GoodsType => options[:goods_type] || 0, # Not Set
              :IndustryType => options[:industry_type] || 2, # Ecommerce
              :OrderNumber => options[:order_id] || generate_order_number,
              :SignatureCaptured => options[:signature_captured] || false
            },
            :TenderData => card_data(credit_card)
          }
        }
        response = http("Txn", options[:workflow_id] || @service_id).post(data)
        transaction = new_transaction_from_response(response)
        respond_with(transaction,
                     response,
                     :success => valid_code?(transaction.code))
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

        response = http("Txn", options[:workflow_id] || @service_id).post(data)
        transaction = new_transaction_from_response(response)
        respond_with(transaction,
                     response,
                     :success => valid_code?(transaction.code))
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

        response = http("Txn", options[:workflow_id] || @service_id, transaction_id).put(data)
        transaction = new_transaction_from_response(response)
        respond_with(transaction,
                     response,
                     :success => valid_code?(transaction.code))
      end


      protected
      
      def valid_code?(code)
        [0,1].include?(code)
      end

      def card_data(credit_card)
        return nil if credit_card.nil?
        { 
          'PaymentAccountDataToken' => credit_card.vault_id,
          'CardData' => { 
            'CardholderName' => credit_card.name_on_card.blank? ? nil : credit_card.name_on_card,
            'CardType' => self.class.credit_card_type_id(credit_card.card_number),
            'Expire' => credit_card.expires_on.try(:strftime, "%m%y"),
            'PAN' => credit_card.vault_id ? ("XXXXXXXXXXX%04d" % [credit_card.card_number[-4..-1]]) : credit_card.card_number
          },
          'CardSecurityData' => {
            'AVSData' => {
              'CardholderName' => credit_card.name_on_card.blank? ? nil : credit_card.name_on_card,
              'Street' => credit_card.street_address.try(:[], (0...20)),
              'City' => credit_card.locality,
              'StateProvince' => credit_card.region,
              'PostalCode' => credit_card.postal_code.try(:gsub, /[^[:alnum:]]/, '').try(:[], (0...8)),
              'Country' => credit_card.country.try(:to_ipcommerce_id),
              'Phone' => credit_card.phone
            }.select { |k, v| !v.nil? },
            'CVDataProvided' => credit_card.cvv_number.nil? ? nil : 2,
            'CVData' => credit_card.cvv_number
          }.select { |k, v| v.is_a?(Hash) ? !v.empty? : !v.nil?  }
        }.select { |k, v| !v.nil? }
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
        VaultedBilling::HTTP.new(self, urls(params), {
          :headers => { 'Content-Type' => 'application/json' },
          :before_request => :before_request,
          :basic_auth => [@service_key_store.key, ""],
          :on_success => :on_success
        })
      end

      def urls(params)
        endpoints.collect do |url|
          url + params.join('/')
        end
      end
      
      def endpoints
        @test_mode ? TestEndpoints : Endpoints
      end

      def before_request(request)
        request.body = MultiJson.encode(request.body)
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
            :avs_response => parse_avs_result(response.body['AVSResult']),
            :cvv_response => parse_cvv_result(response.body['CVResult']),
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

      def parse_avs_result(result)
        return nil unless result
        { 
          :result => result['ActualResult'],
          :address => AvsResults[result['AddressResult']],
          :country => AvsResults[result['CountryResult']],
          :state => AvsResults[result['StateResult']],
          :postal_code => AvsResults[result['PostalCodeResult']],
          :phone => AvsResults[result['PhoneResult']],
          :cardholder_name => AvsResults[result['CardholderNameResult']],
          :city => AvsResults[result['CityResult']]
        }
      end

      def parse_cvv_result(result)
        return nil unless result
        CVResults[result]
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
