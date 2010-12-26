module VaultedBilling
  ##
  # An intermediary object for VaultedBilling which represents a single
  # customer on the gateway.
  #
  # Many gateways support you in defining multiple credit cards or payment
  # methods under a single customer object.  To support this, they will
  # generate one identifier for the top-level customer, and then separate
  # identifiers for each payment method (see VaultedBilling::CreditCard).
  #
  class Customer
    attr_accessor :email # Optional email address for the customer.
    attr_accessor :merchant_id # Optional custom identifier for the customer (i.e. your database key).
    attr_accessor :vault_id # Gateway generated unique identifier for this customer in their system.

    ##
    # You can mass assign the attributes by passing a hash with keys
    # matching attributes of the Customer:
    #
    #     Customer.new(:merchant_id => 1)
    #
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
