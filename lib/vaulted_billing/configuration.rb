
module VaultedBilling
  ##
  # This configuration holds the default values to use when instantiating
  # VaultedBilling gateways.  This configuration is accessed via
  # VaultedBilling.config, or set en mass via a Hash with
  # VaultedBilling.set_config(...).
  #
  class Configuration
    ##
    # This class holds default configuration options for a specific
    # gateway in the library.
    #
    class GatewayConfiguration
      attr_accessor :username, :password, :test_mode

      ##
      # Possible options are:
      #
      # * password - The default password for the gateway.
      # * test_mode - A boolean indicating whether or not to use the test mode of the gateway (sandbox server, test API, etc.)
      # * username - The default username for the gateway.
      #
      # Unless otherwise defined, test_mode will default to being true.
      #
      def initialize(options = {}, &block)
        options = options.with_indifferent_access
        self.username = options[:username]
        self.password = options[:password]
        self.test_mode = options.has_key?(:test_mode) ?
          options[:test_mode] : true
        yield(self) if block_given?
      end
    end

    attr_accessor :logger
    alias :logger? :logger

    attr_accessor :test_mode

    ##
    # Possible options are as follows:
    #
    # * authorize_net_cim - A hash of GatewayConfiguration options for the Authorize.net CIM
    # * bogus - A hash of GatewayConfiguration options for the Bogus gateway
    # * nmi_customer_vault - A hash of GatewayConfiguration options for the NMI Customer Vault
    # * test_mode - A boolean indicating whether or not the system defaults to using the test end points on the gateways.
    #
    def initialize(options = {})
      options = options.with_indifferent_access
      self.test_mode = options.has_key?(:test_mode) ? options[:test_mode] : true
      @_authorize_net_cim = GatewayConfiguration.new(options[:authorize_net_cim]) if options[:authorize_net_cim]
      @_nmi_customer_vault = GatewayConfiguration.new(options[:nmi_customer_vault]) if options[:nmi_customer_vault]
      @_bogus = GatewayConfiguration.new(options[:bogus]) if options[:bogus]
    end

    ##
    # Returns a VaultedBilling::Configuration::GatewayConfiguration 
    # instance to be used for defining default settings for the
    # Authorize.net CIM gateway.
    #
    def authorize_net_cim
      @_authorize_net_cim ||= GatewayConfiguration.new
    end

    ##
    # Returns a VaultedBilling::Configuration::GatewayConfiguration 
    # instance to be used for defining default settings for the
    # NMI Customer Vault gateway.
    #
    def nmi_customer_vault
      @_nmi_customer_vault ||= GatewayConfiguration.new
    end

    ##
    # Returns a VaultedBilling::Configuration::GatewayConfiguration 
    # instance to be used for defining default settings for the
    # Bogus gateway.
    #
    def bogus
      @_bogus ||= GatewayConfiguration.new
    end
  end
end
