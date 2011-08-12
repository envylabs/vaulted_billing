require 'multi_json'
require 'net/http'

module VaultedBilling
  module Gateways
    ##
    # Interface to IPCommerce Wallet.
    #
    # == Example
    #
    #   VaultedBilling::Gateways::IPCommerceWallet.new(:username => 'identity-token', :service_key_store => XXX).tap do |ipc|
    #     customer = ipc.add_customer(Customer.new)
    #     credit_card = ipc.add_credit_card(customer, CreditCard.new)
    #     ipc.purchase(customer, credit_card, 10.00)
    #   end
    #
    class IpcommerceWallet
      include VaultedBilling::Gateway

      class ServiceKeyStore
        attr_reader :identity_token

        def initialize(identity_token)
          @identity_token = identity_token
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
          return true
          @expires_at > Time.now + 5.minutes
        end

        def renew
          # contact ipcommerce sign on for new keys.
        end
      end


      def initialize(options = {})
        @identity_token = options[:username] || VaultedBilling.config.ipcommerce_wallet.username
        @raw_options = options[:raw_options] || VaultedBilling.config.ipcommerce_wallet.raw_options
        @test_mode = options.has_key?(:test) ? options[:test] : (VaultedBilling.config.authorize_net_cim.test_mode || VaultedBilling.config.test_mode)
         @application_id = options[:application_id]
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
              Amount: amount,
              CurrencyCode: 4,
              TransactionDateTime:"2011-03-28T11:26:13.395+00:00",
              CustomerPresent:0,
              EmployeeId:options[:employee_id],
              EntryMode:1,
              GoodsType:0,
              IndustryType:0,
              OrderNumber: options[:order_id],
              SignatureCaptured:false
            },
            TenderData: {
              CardData: {
                CardholderName: nil,
                CardType: 1,
                Expire: "1210",
                PAN: credit_card.card_number
              }
            }
          }
        }
        post('Txn', data)
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


      private


      def post(service_name, data = {})
        encoded_data = MultiJson.encode(data)
        uri = URI.parse("https://cws-01.cert.ipcommerce.com/REST/2.0.15/#{service_name}/E4FB800001")

        request = Net::HTTP::Post.new(uri.path)
        request.initialize_http_header({
          'User-Agent' => "vaulted_billing/#{VaultedBilling::Version}"
        })
        request.body = encoded_data
        request.basic_auth(@service_key_store.key, "")
        request.set_content_type "application/json"
        request.delete "accept"
        response = Net::HTTP.new(uri.host, uri.port).tap do |https|
          https.use_ssl = true
          https.ca_file = VaultedBilling.config.ca_file
          https.verify_mode = OpenSSL::SSL::VERIFY_PEER
        end
        response.request(request)
      end
    end
  end
end
