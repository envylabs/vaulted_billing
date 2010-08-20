module VaultedBilling
  class Customer
    attr_accessor :id
    attr_accessor :email

    def initialize(attributes = {})
      attributes = HashWithIndifferentAccess.new(attributes)
      @id = attributes[:id]
      @email = attributes[:email]
    end
  end
end
