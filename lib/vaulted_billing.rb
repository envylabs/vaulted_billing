begin
  require 'active_support/core_ext/object/blank'
  require 'active_support/core_ext/object/try'
  require 'active_support/core_ext/hash/conversions'
  require 'active_support/core_ext/hash/indifferent_access'
  require 'active_support/core_ext/hash/reverse_merge'
  require 'active_support/core_ext/string/inflections'
rescue LoadError
  require 'active_support'
end

module VaultedBilling
  autoload :Version, 'vaulted_billing/version'
  autoload :Configuration, 'vaulted_billing/configuration'
  autoload :Gateway, 'vaulted_billing/gateway'
  autoload :Gateways, 'vaulted_billing/gateways'
  autoload :Customer, 'vaulted_billing/customer'
  autoload :CreditCard, 'vaulted_billing/credit_card'
  autoload :Transaction, 'vaulted_billing/transaction'
  autoload :HttpsInterface, 'vaulted_billing/https_interface'

  Dir[File.expand_path('../vaulted_billing/core_ext/**/*.rb', __FILE__)].each do |extension|
    require extension
  end

  ##
  # Return the matching gateway for the name provided.
  # 
  # * <tt>:bogus</tt>:: Bogus - always successful, does nothing.
  # * <tt>:nmi_customer_vault</tt>:: NmiCustomerVault
  # * <tt>:authorize_net_cim</tt>:: AuthorizeNetCim
  #
  def self.gateway(name)
    Gateways.const_get(name.to_s.camelize)
  end

  ##
  # Returns the VaultedBilling::Configuration.  This is primarily used to
  # modify the default settings used when new gateways are instantiated.
  #
  def self.config
    @@config ||= VaultedBilling::Configuration.new
  end

  ##
  # A helper method to allow you to set the configuration en mass via
  # a properly formatted Hash of options:
  #
  #     VaultedBilling.set_config({
  #       :test_mode => false,
  #       :authorize_net_cim => {
  #         :username => 'APIName',
  #         :password => 'APIPassword',
  #         :test_mode => false,
  #       :nmi_customer_vault => { ... }
  #     })
  #
  def self.set_config(options = {})
    @@config = VaultedBilling::Configuration.new(options)
  end

  def self.logger; config.logger; end
  def self.logger=(input); config.logger = input; end
  def self.logger?; config.logger?; end
end
