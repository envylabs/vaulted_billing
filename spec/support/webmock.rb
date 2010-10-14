require 'webmock/rspec'

WebMock.disable_net_connect!(:allow_localhost => true)

RSpec.configure do |config|
  config.include(WebMock::API)
end
