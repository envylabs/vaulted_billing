module VaultedBilling
  autoload :Version, 'vaulted_billing/version'
  autoload :Gateway, 'vaulted_billing/gateway'
  autoload :Gateways, 'vaulted_billing/gateways'
  autoload :Customer, 'vaulted_billing/customer'
  autoload :CreditCard, 'vaulted_billing/credit_card'
  autoload :Transaction, 'vaulted_billing/transaction'
  autoload :HttpsInterface, 'vaulted_billing/https_interface'

  mattr_accessor :logger

  Dir[File.expand_path(File.join(File.dirname(__FILE__), 'vaulted_billing', 'core_ext', '**', '*.rb'))].each do |extension|
    require extension
  end

  ##
  # Return the matching gateway for the name provided.
  # 
  # * <tt>bogus</tt>:: BogusGateway - always successful, does nothing.
  # * <tt>nmi_customer_vault</tt>:: NMICustomerVaultGateway
  #
  def self.gateway(name)
    Gateways.const_get(name.to_s.camelize)
  end

  def self.logger?
    @@logger.present?
  end

end
