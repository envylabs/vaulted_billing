$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib')))
require 'rubygems'
require 'bundler'
Bundler.setup
Bundler.require :default, :test

require 'vaulted_billing'
VaultedBilling.logger = Logger.new(STDOUT)
VaultedBilling.logger.level = Logger::INFO

Dir[File.join(File.dirname(__FILE__), 'support', '**', '*.rb')].each do |file|
  require file
end
