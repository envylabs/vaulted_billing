module VaultedBilling
  class Transaction
    attr_accessor :id

    def initialize(attributes = {})
      @id = attributes[:id]
    end
  end
end
