module VaultedBilling
  class CreditCard
    attr_accessor :vault_id
    attr_accessor :currency
    attr_accessor :card_number
    attr_accessor :cvv_number
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

    def to_vaulted_billing; self; end

    def ==(o)
      self.attributes == o.attributes
    end

    def attributes
      {
        :vault_id => vault_id,
        :currency => currency,
        :card_number => card_number,
        :cvv_number => cvv_number,
        :expires_on => expires_on,
        :first_name => first_name,
        :last_name => last_name,
        :street_address => street_address,
        :locality => locality,
        :region => region,
        :postal_code => postal_code,
        :country => country,
        :phone => phone
      }
    end
  end
end
