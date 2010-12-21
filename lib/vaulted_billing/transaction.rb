module VaultedBilling
  class Transaction
    attr_accessor :id
    attr_accessor :authcode
    attr_accessor :avs_response
    attr_accessor :cvv_response
    attr_accessor :code
    attr_accessor :message
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
