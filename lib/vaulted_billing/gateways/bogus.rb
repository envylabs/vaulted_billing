require 'digest/md5'

module VaultedBilling
  module Gateways
    class Bogus
      include VaultedBilling::Gateway

      def add_customer(customer)
        Response.new(true, customer.tap { |c| c.id = Digest::MD5.hexdigest("--#{Time.now.to_f}--#{rand(1_000_000)}--#{rand(1_000_000)}--") })
      end

      def update_customer(customer)
        Response.new(true, customer)
      end

      def remove_customer(customer)
        Response.new(true, customer)
      end

      def add_customer_credit_card(customer, credit_card)
        Response.new(true, credit_card)
      end

      def update_customer_credit_card(customer, credit_card)
        Response.new(true, credit_card)
      end

      def remove_customer_credit_card(customer, credit_card)
        Response.new(true, credit_card)
      end
    end
  end
end
