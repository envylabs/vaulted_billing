module VaultedBilling
  ##
  # This class encapsulates the data returned by the gateway / payment
  # processor for transaction requests.  An instance of this class will
  # be returned from all transaction requests (authorize, capture, 
  # refund, void, etc.) performed against a gateway.
  #
  class Transaction
    # The transaction identifier from the processor
    attr_accessor :id

    # The authorization code for the transaction
    attr_accessor :authcode

    # The address verification service response
    attr_accessor :avs_response

    # The card verification number response
    attr_accessor :cvv_response

    # The response code from the processor
    attr_accessor :code

    # The message from the processor
    attr_accessor :message

    # The masked card number used in the transaction, if available
    attr_accessor :masked_card_number

    def initialize(attributes = {})
      attributes.each_pair do |key, value|
        send("#{key}=", value) if respond_to?("#{key}=")
      end
    end

    def to_vaulted_billing; self; end

    def ==(o)
      attributes == o.attributes
    end

    def attributes
      {
        :id => id,
        :authcode => authcode,
        :avs_response => avs_response,
        :cvv_response => cvv_response,
        :code => code,
        :message => message,
        :masked_card_number => masked_card_number
      }
    end
  end
end
