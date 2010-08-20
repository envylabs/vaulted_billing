require 'digest/md5'

module VaultedBilling
  module Gateways
    class Bogus
      include VaultedBilling::Gateway

      def add_customer(customer)
        Response.new(true, customer.tap { |c| c.id = new_identifier })
      end

      def update_customer(customer)
        Response.new(true, customer)
      end

      def remove_customer(customer)
        Response.new(true, customer)
      end

      def add_customer_credit_card(customer, credit_card)
        Response.new(true, credit_card.tap { |c| c.id = new_identifier })
      end

      def update_customer_credit_card(customer, credit_card)
        Response.new(true, credit_card)
      end

      def remove_customer_credit_card(customer, credit_card)
        Response.new(true, credit_card)
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

      def new_identifier
        Digest::MD5.hexdigest("--#{Time.now.to_f}--#{rand(1_000_000)}--#{rand(1_000_000)}--")
      end
      private :new_identifier

      def transaction_response
        Response.new(true, VaultedBilling::Transaction.new(:id => new_identifier))
      end
      private :transaction_response
    end
  end
end
