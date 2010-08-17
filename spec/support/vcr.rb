VCR.config do |config|
  config.cassette_library_dir = File.expand_path(File.join(File.dirname(__FILE__), 'spec', 'fixtures', 'net'))
  config.default_cassette_options = {
    :record => :none,
    :allow_real_http => :localhost
  }
end

module VCRHelpers
  def current_description
    "#{self.class.description} #{description}"
  end

  def use_cached_requests(options={}, &block)
    scope = options.delete(:scope) || current_description

    if mode = options.delete(:record)
      mode_alises = { :new => :new_episodes }
      options[:record] = mode_alises[mode] || mode
    end

    VCR.use_cassette(scope, options, &block)
  end
end

RSpec.configure do |config|
  config.include VCRHelpers
end
