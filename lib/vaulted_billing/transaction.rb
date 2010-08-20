module VaultedBilling
  class Transaction
    attr_accessor :id
    attr_accessor :authcode
    attr_accessor :avs_response
    attr_accessor :cvv_response
    attr_accessor :code
    attr_accessor :message

    def initialize(attributes = {})
      attributes.each_pair do |key, value|
        send("#{key}=", value) if respond_to?("#{key}=")
      end
    end
  end
end
