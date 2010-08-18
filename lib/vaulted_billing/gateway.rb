module VaultedBilling
  module Gateway
    class Response
      attr_reader :result

      def initialize(success, result)
        @success = success
        @result = result
      end

      def success?; @success; end
    end

    def add_customer(customer)
      raise NotImplementedError
    end

    def update_customer(customer)
      raise NotImplementedError
    end

    def remove_customer(customer)
      raise NotImplementedError
    end

    def add_customer_credit_card(customer, credit_card)
      raise NotImplementedError
    end

    def update_customer_credit_card(customer, credit_card)
      raise NotImplementedError
    end

    def remove_customer_credit_card(customer, credit_card)
      raise NotImplementedError
    end

    def authorize(customer, credit_card, amount)
      raise NotImplementedError
    end

    def capture(transaction_id, amount)
      raise NotImplementedError
    end

    def refund(transaction_id, amount)
      raise NotImplementedError
    end

    def void(transaction_id)
      raise NotImplementedError
    end
  end
end
