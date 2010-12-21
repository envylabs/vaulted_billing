$:.unshift(File.expand_path('../../lib', __FILE__))
require 'rubygems'
require 'bundler'
Bundler.setup
Bundler.require :default, :test

require 'vaulted_billing'

Dir[File.join(File.dirname(__FILE__), 'support', '**', '*.rb')].each do |file|
  require file
end
