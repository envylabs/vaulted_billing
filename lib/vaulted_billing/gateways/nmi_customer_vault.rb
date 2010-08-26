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
        respond_with(credit_card, :success => response.success?, :raw_response => response.raw_response.try(:body)) do |c|
          c.vault_id = response.body['customer_vault_id']
        end
      end

      def update_customer_credit_card(customer, credit_card)
        response = post_data(storage_data('update_customer', customer.to_vaulted_billing, credit_card.to_vaulted_billing))
        respond_with(credit_card, :success => response.success?, :raw_response => response.raw_response.try(:body))
      end

      def remove_customer_credit_card(customer, credit_card)
        response = post_data(core_data.merge({
          :customer_vault => 'delete_customer',
          :customer_vault_id => credit_card.to_vaulted_billing.vault_id
        }).to_querystring)
        respond_with(credit_card, :success => response.success?, :raw_response => response.raw_response.try(:body))
      end

      def authorize(customer, credit_card, amount)
        response = post_data(transaction_data('auth', {
          :customer_vault_id => credit_card.to_vaulted_billing.vault_id,
          :amount => amount
        }))
        respond_with(new_transaction_from_response(response.body),
                     :success => response.success?, :raw_response => response.raw_response.try(:body))
      end

      def capture(transaction_id, amount)
        response = post_data(transaction_data('capture', {
          :transactionid => transaction_id,
          :amount => amount
        }))
        respond_with(new_transaction_from_response(response.body),
                     :success => response.success?, :raw_response => response.raw_response.try(:body))
      end

      def refund(transaction_id, amount)
        response = post_data(transaction_data('refund', {
          :transactionid => transaction_id,
          :amount => amount
        }))
        respond_with(new_transaction_from_response(response.body),
                     :success => response.success?, :raw_response => response.raw_response.try(:body))
      end

      def void(transaction_id)
        response = post_data(transaction_data('void', {
          :transactionid => transaction_id
        }))
        respond_with(new_transaction_from_response(response.body),
                     :success => response.success?, :raw_response => response.raw_response.try(:body))
      end


      protected


      def before_post(data)
        VaultedBilling.logger.debug { "Posting %s to %s" % [data.inspect, uri.to_s] } if VaultedBilling.logger?
      end

      def after_post(response)
        VaultedBilling.logger.debug { "Response code %s (HTTP %d), %s" % [response.message, response.code, response.body.inspect] } if VaultedBilling.logger?
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
          :ccexp => credit_card.expires_on.try(:strftime, "%y%m"),
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
    end
  end
end
