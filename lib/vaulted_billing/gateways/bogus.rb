require 'digest/md5'

module VaultedBilling
  module Gateways
    ##
    # The Bogus gateway should only be used for simple interface testing
    # to the VaultedBilling library.  All customer and credit card requests
    # will always return successfully. All transaction requests (purchase,
    # authorize, capture, etc.) will always return successfully, unless a
    # failure credit card number is given.
    #
    # If a failure credit card number is given, then the transaction amount is
    # used to determine the error message and code to return.
    #
    # The primary purpose of this gateway is to provide you with an end
    # point for testing your interface, as well as a fairly reasonable
    # gateway for performing simple, non-network based tests against.
    #
    # To test failure messages, use the credit card number '4222222222222'.
    # This card number will trigger failed transaction responses from the
    # Bogus gateway for purchase and authorize requests.  In order to receive a
    # specific error message / code, set the transaction amount to one of the
    # following:
    #
    #  0: 'This transaction has been declined.'
    #  1: 'This transaction has been approved.'
    #  2: 'This transaction has been declined.'
    #  3: 'This transaction has been declined.'
    #  4: 'This transaction has been declined.'
    #  5: 'A valid amount is required.'
    #  6: 'The credit card number is invalid.'
    #  7: 'The credit card expiration date is invalid'
    #  8: 'The credit card has expired.'
    #  9: 'The ABA code is invalid'
    #  10: 'The account number is invalid.'
    #  11: 'A duplicate transaction has been submitted.'
    #
    # Example:
    #
    #   customer = Customer.new(...)
    #   credit_card = CreditCard.new(:card_number => '4222222222222')
    #   bogus.purchase(customer, credit_card, 6.00)
    #   # => Failed transaction, 'The credit card number is invalid.'
    #
    class Bogus
      autoload :Failure, 'vaulted_billing/gateways/bogus/failure'

      include VaultedBilling::Gateway
      include VaultedBilling::Gateways::Bogus::Failure


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
        transaction_response credit_card, amount
      end

      def purchase(customer, credit_card, amount, options = {})
        transaction_response credit_card, amount
      end

      def void(transaction_id, options = {})
        transaction_response nil, nil
      end

      def capture(transaction_id, amount, options = {})
        transaction_response nil, amount
      end

      def refund(transaction_id, amount, options = {})
        transaction_response nil, amount
      end


      private


      def new_identifier
        Digest::MD5.hexdigest("--#{Time.now.to_f}--#{rand(1_000_000)}--#{rand(1_000_000)}--")
      end

      def transaction_response(credit_card, amount)
        credit_card = credit_card.to_vaulted_billing if credit_card

        attributes = { :id => new_identifier }
        attributes[:masked_card_number] = "XXXX%04d" % [credit_card ? credit_card.card_number.to_s[-4..-1].to_i : rand(9999)]
        success = true
        error_code = nil
        message = 'Success'

        if success?(credit_card, amount)
          attributes[:authcode] = new_identifier[0..5]
        else
          success = false
          attributes[:message] = message = failure_message_for(credit_card, amount)
          error_code = error_code_for(credit_card, amount)
        end

        respond_with VaultedBilling::Transaction.new(attributes), :success => success, :error_code => error_code, :response_message => message
      end
    end
  end
end
