require 'pathname'
require 'yaml'

path = Pathname.new(File.expand_path('../../config.yml', __FILE__))
if path.exist?
  VaultedBilling.set_config(YAML.load_file(path.to_s))
else
  abort "Please setup a #{path} file."
end
