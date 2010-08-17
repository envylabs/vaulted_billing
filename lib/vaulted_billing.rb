module VaultedBilling
  autoload :Gateway, 'vaulted_billing/gateway'
  autoload :Gateways, 'vaulted_billing/gateways'
  autoload :Customer, 'vaulted_billing/customer'
  autoload :CreditCard, 'vaulted_billing/credit_card'

  ##
  # Return the matching gateway for the name provided.
  # 
  # * <tt>bogus</tt>:: BogusGateway - always successful, does nothing.
  # * <tt>nmi_customer_vault</tt>:: NMICustomerVaultGateway
  #
  def self.gateway(name)
    Gateways.const_get(name.to_s.camelize)
  end

end
