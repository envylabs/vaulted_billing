Dir[File.expand_path(File.join(File.dirname(__FILE__), '..', 'factories', '**', '*.rb'))].each do |factory|
  require factory
end
