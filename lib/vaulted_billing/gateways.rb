module VaultedBilling
  module Gateways
    Dir[File.expand_path(File.join(File.dirname(__FILE__), 'gateways', '*.rb'))].each do |file|
      filename = File.basename(file, '.rb')
      gateway_class = filename.camelize
      autoload gateway_class, file
    end
  end
end
