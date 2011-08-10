$:.unshift(File.expand_path('../../lib', __FILE__))
require 'rubygems'
require 'bundler/setup'
Bundler.require :default, :test

require 'vaulted_billing'
require 'rspec'

Dir[File.join(File.dirname(__FILE__), 'support', '**', '*.rb')].each do |file|
  require file
end

RSpec.configure do |config|
  config.mock_with :rspec
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
end
