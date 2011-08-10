$:.unshift(File.expand_path('../../lib', __FILE__))
require 'rubygems'
require 'bundler/setup'
Bundler.require :default, :test

Dir[File.join(File.dirname(__FILE__), 'support/**/*.rb')].each { |f| require f }

RSpec.configure do |config|
  config.mock_with :rspec
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
end
