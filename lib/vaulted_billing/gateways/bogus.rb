require 'digest/md5'

module VaultedBilling
  module Gateways
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

      def add_customer_credit_card(customer, credit_card)
        respond_with(credit_card.to_vaulted_billing) { |c| c.vault_id = new_identifier }
      end

      def update_customer_credit_card(customer, credit_card)
        respond_with credit_card.to_vaulted_billing
      end

      def remove_customer_credit_card(customer, credit_card)
        respond_with credit_card.to_vaulted_billing
      end

      def authorize(customer, credit_card, amount)
        transaction_response
      end

      def void(transaction_id)
        transaction_response
      end

      def capture(transaction_id, amount)
        transaction_response
      end

      def refund(transaction_id, amount)
        transaction_response
      end


      private


      def new_identifier
        Digest::MD5.hexdigest("--#{Time.now.to_f}--#{rand(1_000_000)}--#{rand(1_000_000)}--")
      end

      def transaction_response
        respond_with VaultedBilling::Transaction.new({
          :id => new_identifier,
          :authcode => new_identifier[0..5]
        })
      end
    end
  end
end
