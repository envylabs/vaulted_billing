require 'net/https'
require 'uri'

module VaultedBilling
  module HttpsInterface

    HTTP_ERRORS = [
      Timeout::Error,
      Errno::EINVAL,
      Errno::ECONNRESET,
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

      def initialize(http_response)
        if http_response
          self.raw_response = http_response
#          self.code = http_response.code
#          self.message = http_response.message
          self.body = http_response.body
          self.success = ((http_response.code =~ /^2\d{2}/) == 0)
        end
      end

      alias :success? :success
      alias :status_code :code
    end

    attr_writer :use_test_uri
    attr_writer :ssl_pem

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
        'User-Agent' => "vaulted_billing #{VaultedBilling::Version}"
      }.reverse_merge(request_headers))
      request.body = data
      response = Net::HTTP.new(uri.host, uri.port).tap do |https|
        https.use_ssl = true
        if @ssl_pem
          https.cert = OpenSSL::X509::Certificate.new(@ssl_pem)
          https.verify_mode = OpenSSL::SSL::VERIFY_PEER
        else
          https.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
      end

      before_post(data)

      begin
        PostResponse.new(response.request(request)).tap do |post_response|
          after_post(post_response)
        end
      rescue *HTTP_ERRORS
        PostResponse.new(nil).tap do |post_response|
          post_response.success = false
          post_response.message = "%s - %s" % [$!.class.name, $!.message]
          after_post(post_response)
        end
      end
    end
    protected :post_data

    def before_post(data)
    end
    protected :before_post

    def after_post(response)
    end
    protected :after_post
  end
end
