module VaultedBilling
  module Gateways
    class Bogus
      module Failure
        FailureCards = %w(4222222222222)
        FailureMessages = [
          'This transaction has been declined.',
          'This transaction has been approved.',
          'This transaction has been declined.',
          'This transaction has been declined.',
          'This transaction has been declined.',
          'A valid amount is required.',
          'The credit card number is invalid.',
          'The credit card expiration date is invalid',
          'The credit card has expired.',
          'The ABA code is invalid',
          'The account number is invalid.',
          'A duplicate transaction has been submitted.',
        ]


        protected


        def error_code_for(credit_card, amount)
          amount.to_i
        end

        def failure_message_for(credit_card, amount)
          FailureMessages[error_code_for(credit_card, amount)] || FailureMessages.first
        end

        def success?(credit_card, amount)
          credit_card.nil? || !failure?(credit_card, amount)
        end

        def failure?(credit_card, amount)
          !credit_card.nil? && FailureCards.include?(credit_card.card_number)
        end
      end
    end
  end
end
