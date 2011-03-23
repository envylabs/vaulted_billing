require 'net/https'
require 'uri'

module VaultedBilling
  module HttpsInterface

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

    class PostResponse
      attr_accessor :code
      attr_accessor :message
      attr_accessor :body
      attr_accessor :success
      attr_accessor :raw_response
      attr_accessor :connection_error

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

    attr_writer :use_test_uri

    def live_uri=(input)
      @live_uri = input ? URI.parse(input) : nil
    end

    def test_uri=(input)
      @test_uri = input ? URI.parse(input) : nil
    end

    ##
    # Returns the protocol and host and any path details that is used
    # when making communications.
    #
    def uri
      @use_test_uri ? @test_uri : @live_uri
    end

    ##
    # Posts the given data to the uri and returns the response.
    #
    def post_data(data, request_headers = {})
      request = Net::HTTP::Post.new(uri.path)
      request.initialize_http_header({
        'User-Agent' => "vaulted_billing/#{VaultedBilling::Version}"
      }.reverse_merge(request_headers))
      request.body = data
      response = Net::HTTP.new(uri.host, uri.port).tap do |https|
        https.use_ssl = true
        https.ca_file = VaultedBilling.config.ca_file
        https.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end

      before_post_caller(data)

      begin
        PostResponse.new(response.request(request)).tap do |post_response|
          after_post_caller(post_response)
          after_post_on_success(post_response)
        end
      rescue *HTTP_ERRORS
        PostResponse.new(nil).tap do |post_response|
          post_response.success = false
          post_response.message = "%s - %s" % [$!.class.name, $!.message]
          post_response.connection_error = true
          after_post_caller(post_response)
          after_post_on_exception(post_response, $!)
        end
      end
    end
    protected :post_data

    def before_post(data)
    end
    protected :before_post

    def before_post_caller(data)
      if VaultedBilling.logger?
        VaultedBilling.logger.debug { "Posting %s to %s" % [data.inspect, uri.to_s] }
      end
      before_post(data)
    end
    private :before_post_caller

    def after_post(response)
    end
    protected :after_post

    def after_post_caller(response)
      if VaultedBilling.logger?
        VaultedBilling.logger.info { "Response code %s (HTTP %s), %s" % [response.message, response.code.presence || '0', response.body.inspect] }
      end
      after_post(response)
    end
    private :after_post_caller

    def after_post_on_success(response)
    end
    protected :after_post_on_success

    def after_post_on_exception(response, exception)
    end
    protected :after_post_on_exception
  end
end
