module VaultedBilling
  module Gateways

    ##
    # An interface to the NMI Customer Vault.
    #
    # Currently, the Customer Vault is setup to be one-to-one with
    # a customer to a credit card.  Unlike Authorize.net's CIM, a 
    # single customer cannot carry multiple credit cards.  Therefore
    # most of the individual customer manipulation methods are
    # simply stubbed to always be successful.  The meat of the library
    # is in the credit card methods and transactions.
    # 
    class NmiCustomerVault
      include VaultedBilling::Gateway
      include VaultedBilling::HttpsInterface

      def initialize(options = {})
        self.live_uri = self.test_uri = "https://secure.nmi.com/api/transact.php"
        self.ssl_pem = File.read(File.expand_path(File.join(File.dirname(__FILE__), '..', 'certificate_authorities', 'verisign.pem')))

        options = HashWithIndifferentAccess.new(options)
        @username = options[:username]
        @password = options[:password]
        self.use_test_uri = options[:test]
      end

      ##
      # A stub, since the vault requires both customer information
      # and credit card information.  Actual additions are handled
      # via the add_customer_credit_card method.
      #
      def add_customer(customer)
        respond_with customer.to_vaulted_billing
      end

      ##
      # A stub, since the vault requires both customer information
      # and credit card information.  Actual modifications are
      # handled via the update_customer_credit_card method.
      #
      def update_customer(customer)
        respond_with customer.to_vaulted_billing
      end

      ##
      # A stub, since the vault requires both customer information
      # and credit card information.  Actual removals are
      # handled via the remove_customer_credit_card method.
      #
      def remove_customer(customer)
        respond_with customer.to_vaulted_billing
      end

      def add_customer_credit_card(customer, credit_card)
        response = post_data(storage_data('add_customer', customer.to_vaulted_billing, credit_card.to_vaulted_billing))
        respond_with(credit_card, response, :success => response.success?) do |c|
          c.vault_id = response.body['customer_vault_id']
        end
      end

      def update_customer_credit_card(customer, credit_card)
        response = post_data(storage_data('update_customer', customer.to_vaulted_billing, credit_card.to_vaulted_billing))
        respond_with(credit_card, response, :success => response.success?)
      end

      def remove_customer_credit_card(customer, credit_card)
        response = post_data(core_data.merge({
          :customer_vault => 'delete_customer',
          :customer_vault_id => credit_card.to_vaulted_billing.vault_id
        }).to_querystring)
        respond_with(credit_card, response, :success => response.success?)
      end

      def purchase(customer, credit_card, amount)
        response = post_data(transaction_data('sale', {
          :customer_vault_id => credit_card.to_vaulted_billing.vault_id,
          :amount => amount
        }))
        respond_with(new_transaction_from_response(response.body),
                     response,
                     :success => response.success?)
      end

      def authorize(customer, credit_card, amount)
        response = post_data(transaction_data('auth', {
          :customer_vault_id => credit_card.to_vaulted_billing.vault_id,
          :amount => amount
        }))
        respond_with(new_transaction_from_response(response.body),
                     response,
                     :success => response.success?)
      end

      def capture(transaction_id, amount)
        response = post_data(transaction_data('capture', {
          :transactionid => transaction_id,
          :amount => amount
        }))
        respond_with(new_transaction_from_response(response.body),
                     response,
                     :success => response.success?)
      end

      def refund(transaction_id, amount)
        response = post_data(transaction_data('refund', {
          :transactionid => transaction_id,
          :amount => amount
        }))
        respond_with(new_transaction_from_response(response.body),
                     response,
                     :success => response.success?)
      end

      def void(transaction_id)
        response = post_data(transaction_data('void', {
          :transactionid => transaction_id
        }))
        respond_with(new_transaction_from_response(response.body),
                     response,
                     :success => response.success?)
      end


      protected


      def after_post_on_exception(response, exception)
        response.body = {
          'response' => '3',
          'responsetext' => 'A communication problem has occurred.',
          'response_code' => '420'
        }
        response.success = false
      end

      def after_post(response)
        response.body = Hash.from_querystring(response.body)
        response.success = response.body['response'] == '1'
      end


      private


      def core_data
        {
          :username => @username,
          :password => @password
        }
      end

      def transaction_data(method, overrides = {})
        core_data.merge({
          :type => method.to_s
        }).merge(overrides).to_querystring
      end

      def storage_data(method, customer, credit_card)
        core_data.merge({
          :customer_vault => method.to_s,
          :customer_vault_id => credit_card.vault_id,
          :currency => credit_card.currency,
          :method => 'creditcard',
          :ccnumber => credit_card.card_number,
          :ccexp => credit_card.expires_on.try(:strftime, "%m%y"),
          :first_name => credit_card.first_name,
          :last_name => credit_card.last_name,
          :address1 => credit_card.street_address,
          :city => credit_card.locality,
          :state => credit_card.region,
          :zip => credit_card.postal_code,
          :country => credit_card.country,
          :phone => credit_card.phone,
          :email => customer.email
        }).to_querystring
      end

      def new_transaction_from_response(response)
        Transaction.new({
          :id => response['transactionid'],
          :avs_response => response['avsresponse'] == 'Y',
          :cvv_response => response['cvvresponse'] == 'Y',
          :authcode => response['authcode'],
          :message => response['responsetext'],
          :code => response['response_code']
        })
      end

      def respond_with(object, response = nil, options = {}, &block)
        super(object, options, &block).tap do |o|
          if response
            o.raw_response = response.raw_response.try(:body)
            o.connection_error = response.connection_error
            o.response_message = (response.body || {})['responsetext']
            unless response.success?
              o.error_code = (response.body || {})['response_code']
            end
          end
        end
      end
    end
  end
end
