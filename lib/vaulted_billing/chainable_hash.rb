module VaultedBilling
  class ChainableHash < ::Hash
    def initialize
      super { |hash, key| ChainableHash.new }
    end
  end
end