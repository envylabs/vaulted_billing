VCR.config do |config|
  config.cassette_library_dir = File.expand_path(File.join(File.dirname(__FILE__), '..', 'fixtures', 'net'))
  config.default_cassette_options = {
    :record => :none,
    :ignore_localhost => true
  }
  config.http_stubbing_library = :webmock
end

module VCRHelpers
  module InstanceMethods
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

  module ClassMethods
    def cached_request_context(description, options = {}, &block)
      context(description) do
        before(:each) do
          scope = options[:scope] || description

          if mode = options[:record]
            mode_aliases = { :new => :new_episodes }
            options[:record] = mode_aliases[mode] || mode
          end

          VCR.insert_cassette(scope, options.except(:scope))
        end

        after(:each) do
          VCR.eject_cassette
        end

        context(&block)
      end
    end
  end
end

RSpec.configure do |config|
  config.include VCRHelpers::InstanceMethods
  config.extend VCRHelpers::ClassMethods
end