lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'vaulted_billing/version'

Gem::Specification.new do |s|
  s.name = 'vaulted_billing'
  s.version = VaultedBilling::Version
  s.platform = Gem::Platform::RUBY
  s.authors = ['Nathaniel Bibler']
  s.email = ['nate@envylabs.com']
  s.homepage = 'http://github.com/envylabs/vaulted_billing'
  s.summary = 'A library for working with credit card storage gateways'
  s.description = 'Several card processors and gateways support offloading the storage of credit card information onto their service.  This offloads PCI compliance to the gateway rather than keeping it with each retailer.  This library abstracts the interface to many of them, making it trivial to work with any or all of them.'
  s.required_rubygems_version = '>= 1.3.6'

  s.add_dependency 'activesupport', '>= 2.3'
  s.add_dependency 'builder', '>= 2.1.2'

  s.add_development_dependency 'rspec', '>= 2.0.0.beta.19'
  s.add_development_dependency 'vcr', '>= 1.0.3'
  s.add_development_dependency 'webmock', '>= 1.3.4'
  s.add_development_dependency 'factory_girl', '>= 1.3.2'
  s.add_development_dependency 'faker', '>= 0.3.1'

  s.files = Dir.glob("lib/**/*") + %w(README.md)
  s.require_path = 'lib'
end
