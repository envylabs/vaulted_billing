module VaultedBilling
  class Configuration
    class GatewayConfiguration #:nodoc:
      attr_accessor :username, :password, :test_mode

      def initialize(options = {}, &block)
        options = options.with_indifferent_access
        self.username = options[:username]
        self.password = options[:password]
        self.test_mode = options.has_key?(:test_mode) ? options[:test_mode] : true
        yield(self) if block_given?
      end
    end

    attr_accessor :logger
    alias :logger? :logger

    attr_accessor :test_mode

    def initialize(options = {})
      options = options.with_indifferent_access
      self.test_mode = options.has_key?(:test_mode) ? options[:test_mode] : true
      @_authorize_net_cim = GatewayConfiguration.new(options[:authorize_net_cim]) if options[:authorize_net_cim]
      @_nmi_customer_vault = GatewayConfiguration.new(options[:nmi_customer_vault]) if options[:nmi_customer_vault]
      @_bogus = GatewayConfiguration.new(options[:bogus]) if options[:bogus]
    end

    def authorize_net_cim
      @_authorize_net_cim ||= GatewayConfiguration.new
    end

    def nmi_customer_vault
      @_nmi_customer_vault ||= GatewayConfiguration.new
    end

    def bogus
      @_bogus ||= GatewayConfiguration.new
    end
  end
end
