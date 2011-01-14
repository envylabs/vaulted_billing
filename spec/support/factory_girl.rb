require 'factory_girl'

Dir[File.expand_path('../../factories/**/*.rb', __FILE__)].each do |factory|
  require factory
end
