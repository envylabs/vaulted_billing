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
      end

      ##
      # A stub, since the vault requires both customer information
      # and credit card information.  Actual additions are handled
      # via the add_customer_credit_card method.
      #
      def add_customer(customer)
        Response.new(true, customer)
      end

      ##
      # A stub, since the vault requires both customer information
      # and credit card information.  Actual modifications are
      # handled via the update_customer_credit_card method.
      #
      #--
      # TODO: Somehow update the customer object if an ID is on the customer?  No idea how it would get there, though.
      #++
      #
      def update_customer(customer)
        Response.new(true, customer)
      end

      ##
      # A stub, since the vault requires both customer information
      # and credit card information.  Actual removals are
      # handled via the remove_customer_credit_card method.
      #
      #--
      # TODO: Somehow remove the customer + credit card combo here.  Maybe use the same identifier for both customer and credit card?
      #++
      #
      def remove_customer(customer)
        Response.new(true, customer)
      end

      def add_customer_credit_card(customer, credit_card)
        response = post_data(data('add_customer', customer, credit_card))
        Response.new(response.success?, credit_card.tap { |c| c.id = response.body['customer_vault_id'] })
      end

      def update_customer_credit_card(customer, credit_card)
        response = post_data(data('update_customer', customer, credit_card))
        Response.new(response.success?, credit_card)
      end

      def remove_customer_credit_card(customer, credit_card)
        response = post_data({
          :username => @username,
          :password => @password,
          :customer_vault => 'delete_customer',
          :customer_vault_id => credit_card.id
        }.to_querystring)
        Response.new(response.success?, credit_card)
      end

      def authorize(customer, credit_card, amount)
        response = post_data({
          :username => @username,
          :password => @password,
          :customer_vault_id => credit_card.id,
          :amount => amount,
          :type => 'auth'
        }.to_querystring)
        Response.new(response.success?, Transaction.new({
          :id => response.body['transactionid'],
          :avs_response => response.body['avsresponse'] == 'Y',
          :cvv_response => response.body['cvvresponse'] == 'Y',
          :authcode => response.body['authcode'],
          :message => response.body['responsetext'],
          :code => response.body['response_code'],
        }))
      end

      def capture(transaction_id, amount)
        response = post_data({
          :username => @username,
          :password => @password,
          :transactionid => transaction_id,
          :amount => amount,
          :type => 'capture'
        }.to_querystring)
        Response.new(response.success?, Transaction.new({
          :id => response.body['transactionid'],
          :avs_response => response.body['avsresponse'] == 'Y',
          :cvv_response => response.body['cvvresponse'] == 'Y',
          :authcode => response.body['authcode'],
          :message => response.body['responsetext'],
          :code => response.body['response_code'],
        }))
      end

      def refund(transaction_id, amount)
        response = post_data({
          :username => @username,
          :password => @password,
          :transactionid => transaction_id,
          :amount => amount,
          :type => 'refund'
        }.to_querystring)
        Response.new(response.success?, Transaction.new({
          :id => response.body['transactionid'],
          :avs_response => response.body['avsresponse'] == 'Y',
          :cvv_response => response.body['cvvresponse'] == 'Y',
          :authcode => response.body['authcode'],
          :message => response.body['responsetext'],
          :code => response.body['response_code'],
        }))
      end

      def void(transaction_id)
        response = post_data({
          :username => @username,
          :password => @password,
          :transactionid => transaction_id,
          :type => 'void'
        }.to_querystring)
        Response.new(response.success?, Transaction.new({
          :id => response.body['transactionid'],
          :avs_response => response.body['avsresponse'] == 'Y',
          :cvv_response => response.body['cvvresponse'] == 'Y',
          :authcode => response.body['authcode'],
          :message => response.body['responsetext'],
          :code => response.body['response_code'],
        }))
      end

      def before_post(data)
        VaultedBilling.logger.debug { "Posting %s to %s" % [data.inspect, uri.to_s] }
      end
      protected :before_post

      def after_post(response)
        VaultedBilling.logger.debug { "Response code %s (HTTP %d), %s" % [response.message, response.code, response.body.inspect] }
        response.body = Hash.from_querystring(response.body)
        response.success = response.body['response'] == '1'
      end
      protected :after_post

      def data(method, customer, credit_card)
        {
          :customer_vault => method.to_s,
          :customer_vault_id => credit_card.id,
          :username => @username,
          :password => @password,
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
        }.to_querystring
      end
      private :data
    end
  end
end
