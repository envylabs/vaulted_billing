require 'digest/md5'

module VaultedBilling
  module Gateways
    ##
    # The Bogus gateway should only be used for simple interface testing
    # to the VaultedBilling library.  All customer and credit card requests
    # will always return successfully.  All transaction requests (purchase,
    # authorize, capture, etc.) will always return successfully.
    #
    # The primary purpose of this gateway is to provide you with an end
    # point for testing your interface, as well as a fairly reasonable
    # gateway for performing simple, non-network based tests against.
    #
    class Bogus
      include VaultedBilling::Gateway

      def initialize(options = {})
      end

      def add_customer(customer)
        respond_with(customer.to_vaulted_billing) { |c| c.vault_id = new_identifier }
      end

      def update_customer(customer)
        respond_with customer.to_vaulted_billing
      end

      def remove_customer(customer)
        respond_with customer.to_vaulted_billing
      end

      def add_customer_credit_card(customer, credit_card, options = {})
        respond_with(credit_card.to_vaulted_billing) { |c| c.vault_id = new_identifier }
      end

      def update_customer_credit_card(customer, credit_card, options = {})
        respond_with credit_card.to_vaulted_billing
      end

      def remove_customer_credit_card(customer, credit_card)
        respond_with credit_card.to_vaulted_billing
      end

      def authorize(customer, credit_card, amount, options = {})
        transaction_response
      end

      def purchase(customer, credit_card, amount, options = {})
        transaction_response
      end

      def void(transaction_id, options = {})
        transaction_response
      end

      def capture(transaction_id, amount, options = {})
        transaction_response
      end

      def refund(transaction_id, amount, options = {})
        transaction_response
      end


      private


      def new_identifier
        Digest::MD5.hexdigest("--#{Time.now.to_f}--#{rand(1_000_000)}--#{rand(1_000_000)}--")
      end

      def transaction_response
        respond_with VaultedBilling::Transaction.new({
          :id => new_identifier,
          :authcode => new_identifier[0..5],
          :masked_card_number => "XXXX%04d" % [rand(9999)]
        })
      end
    end
  end
end