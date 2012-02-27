require 'uri'
require 'net/http'

module VaultedBilling
  class HTTP
    HTTP_ERRORS = [
      Timeout::Error,
      Errno::ETIMEDOUT,
      Errno::EINVAL,
      Errno::ECONNRESET,
      Errno::ECONNREFUSED,
      Errno::EHOSTUNREACH,
      EOFError,
      Net::HTTPBadResponse,
      Net::HTTPHeaderSyntaxError,
      Net::ProtocolError
    ] unless defined?(HTTP_ERRORS)
    
    
     class Response
        attr_accessor :code
        attr_accessor :message
        attr_accessor :body
        attr_accessor :success
        attr_accessor :raw_response
        attr_accessor :connection_error
        alias :connection_error? :connection_error

        def initialize(http_response)
          if http_response
            self.raw_response = http_response
            self.code = http_response.code
            self.message = http_response.message
            self.body = http_response.body
            self.success = ((http_response.code =~ /^2\d{2}/) == 0)
            self.connection_error = false
          end
        end

        alias :success? :success
        alias :status_code :code
      end
    
    attr_reader :uri
    
    def initialize(caller, uri, options = {})
      @uri = [uri].flatten.compact.collect { |u| URI.parse(u.to_s).normalize }
      @headers = options[:headers] || {}
      @basic_auth = options[:basic_auth]
      @content_type = options[:content_type]
      @caller = caller
      @before_request = options[:before_request]
      @on_success = options[:on_success]
      @on_error = options[:on_error]
      @on_complete = options[:on_complete]
    end
    
    def post(body, options = {})
      request(:post, uri.dup, body, options)
    end
    
    def get(options = {})
      request(:get, uri.dup, nil, options)
    end

    def put(body, options = {})
      request(:put, uri.dup, body, options)
    end
    
    private
    
    
    def log(level, string)
      if VaultedBilling.logger?
        VaultedBilling.logger.send(level) { string }
      end
    end
    
    def request(method, uris, body = nil, options = {})
      uri = uris.shift || raise(ArgumentError, "URI is empty")
      query = options.delete(:query)
      path = uri.path
      path << "?#{URI.escape(query)}" if query

      request = case method
      when :get
        Net::HTTP::Get
      when :put
        Net::HTTP::Put
      when :post
        Net::HTTP::Post
      else
        raise ArugmentError
      end.new(path)

      request.initialize_http_header(@headers.merge(options[:headers] || {}).reverse_merge({
         'User-Agent' => user_agent_string
      }))

      request.body = body if body
      set_basic_auth request, options[:basic_auth] || @basic_auth
      set_content_type request, options[:content_type] || @content_type

      response = Net::HTTP.new(uri.host, uri.port).tap do |https|
        https.read_timeout = options[:read_timeout] || 60
        https.open_timeout = options[:open_timeout] || 60
        https.use_ssl = true
        https.ca_file = VaultedBilling.config.ca_file
        https.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end

      run_callback(:before_request, options[:before_request] || @before_request, request)
      http_response = run_request(request, response, options)

      if http_response.connection_error && uris.present?
        request(method, uris, body, options)
      else
        run_callback(:on_complete, options[:on_complete] || @on_complete, http_response)
        http_response
      end
    end
    
    def run_callback(type, callback, *payload)
      case callback
      when Proc
        callback.call(*payload)
      when String, Symbol
        @caller.send(callback, *payload)
      end
    end
    
    def run_request(request, response, options)
      log :debug, "%s %s to %s" % [request.class.name.split('::').last, request.body.inspect, uri.to_s]
      
      http_response = Response.new(response.request(request))
      log :info, "Response code %s (HTTP %s), %s" % [http_response.message, http_response.code.presence || '0', http_response.body.inspect]
      run_callback(:on_success, options[:on_success] || @on_success, http_response)
      http_response
    rescue *HTTP_ERRORS
      log :info, "HTTP Error: %s - %s" % [$!.class.name, $!.message]
      Response.new(nil).tap do |request_response|
        request_response.success = false
        request_response.message = "%s - %s" % [$!.class.name, $!.message]
        request_response.connection_error = true
        run_callback(:on_error, options[:on_error] || @on_error, request_response, $!)
      end
    end
    
    def set_content_type(request, content)
      request.set_content_type(content) if content
    end
    
    def set_basic_auth(request, auth)
      request.basic_auth(auth.first, auth.last) if auth
    end

    def user_agent_string
      "vaulted_billing/%s (Rubygems; Ruby %s %s)" % [VaultedBilling::Version, RUBY_VERSION, RUBY_PLATFORM]
    end
  end
end
