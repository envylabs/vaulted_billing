lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'vaulted_billing/version'

Gem::Specification.new do |s|
  s.name = 'vaulted_billing'
  s.version = VaultedBilling::Version
  s.license = 'MIT'
  s.platform = Gem::Platform::RUBY
  s.authors = ['Nathaniel Bibler']
  s.email = ['nate@envylabs.com']
  s.homepage = 'https://github.com/envylabs/vaulted_billing'
  s.summary = 'A library for working with credit card storage gateways'
  s.description = 'Several card processors and gateways support offloading the storage of credit card information onto their service.  This offloads PCI compliance to the gateway rather than keeping it with each retailer.  This library abstracts the interface to many of them, making it trivial to work with any or all of them.'
  s.required_rubygems_version = '>= 1.3.6'

  s.add_dependency 'activesupport', '>=2.3'
  s.add_dependency 'builder', '>=2.1.2'
  s.add_dependency 'multi_json', '~>1.0'
  s.add_dependency 'multi_xml', '~>0.3.0'
  s.add_dependency 'countries'

  s.add_development_dependency 'rspec', '~>2.4'
  s.add_development_dependency 'vcr', '~>1.7'
  s.add_development_dependency 'webmock', '~>1.6'
  s.add_development_dependency 'factory_girl', '~>1.3'
  s.add_development_dependency 'faker', '~>0.9'
  s.add_development_dependency 'rake', '~>0.9'
  s.add_development_dependency 'watchr'
  s.add_development_dependency 'open4'
  s.add_development_dependency 'appraisal'

  s.files = `git ls-files -- lib/*`.split("\n")
  s.files += %w(README.md LICENSE)
  s.test_files = `git ls-files -- spec/*`.split("\n")
  s.require_path = 'lib'
end
