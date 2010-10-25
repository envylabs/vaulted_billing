module VaultedBilling
  module Gateway
    module Response
      attr_accessor :raw_response
      attr_accessor :response_message
      attr_accessor :error_code
      attr_writer :success
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


    protected


    def respond_with(object, options = {})
      object.tap do |o|
        o.extend(VaultedBilling::Gateway::Response)
        o.success = options.has_key?(:success) ? options[:success] : true
        o.raw_response = options[:raw_response] || ''
        o.response_message = options[:response_message]
        o.error_code = options[:error_code]
        yield(o) if block_given?
      end
    end
  end
end
