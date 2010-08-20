module VaultedBilling
  class CreditCard
    attr_accessor :id
    attr_accessor :currency
    attr_accessor :card_number
    attr_accessor :expires_on
    attr_accessor :first_name
    attr_accessor :last_name
    attr_accessor :street_address
    attr_accessor :locality
    attr_accessor :region
    attr_accessor :postal_code
    attr_accessor :country
    attr_accessor :phone

    def initialize(attributes = {})
      attributes = HashWithIndifferentAccess.new(attributes)
      attributes.each_pair do |key, value|
        send("#{key}=", value) if respond_to?("#{key}=")
      end
    end
  end
end
