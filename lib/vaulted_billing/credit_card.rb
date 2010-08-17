module VaultedBilling
  class CreditCard
    attr_accessor :id

    def initialize(attributes = {})
      @id = attributes[:id]
    end
  end
end
