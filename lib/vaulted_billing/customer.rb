module VaultedBilling
  class Customer
    attr_accessor :vault_id
    attr_accessor :merchant_id
    attr_accessor :email

    def initialize(attributes = {})
      attributes = HashWithIndifferentAccess.new(attributes)
      @vault_id = attributes[:vault_id]
      @merchant_id = attributes[:merchant_id]
      @email = attributes[:email]
    end

    def to_vaulted_billing; self; end

    def ==(o)
      self.attributes == o.attributes
    end

    def attributes
      {
        :vault_id => vault_id,
        :merchant_id => merchant_id,
        :email => email
      }
    end
  end
end
