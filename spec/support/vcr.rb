require 'vcr'

VCR.config do |config|
  config.cassette_library_dir = File.expand_path('../../fixtures/net', __FILE__)
  config.stub_with :webmock
  config.ignore_localhost = true
  config.default_cassette_options = { :record => :none }
  config.filter_sensitive_data('%{NMI_CUSTOMER_VAULT_USERNAME}') { VaultedBilling.config.nmi_customer_vault.username }
  config.filter_sensitive_data('%{NMI_CUSTOMER_VAULT_PASSWORD}') { VaultedBilling.config.nmi_customer_vault.password }
  config.filter_sensitive_data('%{AUTHORIZE_NET_CIM_USERNAME}') { VaultedBilling.config.authorize_net_cim.username }
  config.filter_sensitive_data('%{AUTHORIZE_NET_CIM_PASSWORD}') { VaultedBilling.config.authorize_net_cim.username }
end

module VCRHelpers
  module InstanceMethods
    def current_description
      "#{self.class.description} #{description}"
    end

    def use_cached_requests(options={}, &block)
      scope = options.delete(:scope) || current_description

      if mode = options.delete(:record)
        mode_alises = { :new => :new_episodes }
        options[:record] = mode_alises[mode] || mode
      end

      VCR.use_cassette(scope, options, &block)
    end
  end

  module ClassMethods
    def request_exception_context(description = 'with a connection exception', exception = Timeout::Error, &block)
      context(description) do
        before(:each) { WebMock.stub_request(:any, //).to_raise(exception) }
        context(&block)
      end
    end
  end
end

RSpec.configure do |config|
  config.extend VCR::RSpec::Macros
  config.include VCRHelpers::InstanceMethods
  config.extend VCRHelpers::ClassMethods
end
