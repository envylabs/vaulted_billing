require File.expand_path('../../../spec_helper', __FILE__)

class CallerObject
  def before_request(request); end
  def on_complete(response); end
  def on_success(response); end
  def on_error(response, error); end
end

describe VaultedBilling::HTTP do
  let(:http) { VaultedBilling::HTTP.new(callback_object, url, {
    :before_request => :before_request,
    :on_complete => :on_complete,
    :on_success => :on_success,
    :on_error => :on_error
  }) }

  let(:callback_object) { CallerObject.new }

  let(:url) { 'https://1.2.3.4/' }
  
  after(:each) { WebMock.reset! }

  shared_examples_for "a request with callbacks"  do |net_request|
    it 'runs the before_request callback before submission' do
      callback_object.should_receive(:before_request).with(an_instance_of(net_request)).and_raise(RuntimeError)
      expect {
        subject
      }.to raise_error(RuntimeError)
      WebMock.should_not have_requested(:any, url)
    end
    
    it 'runs the on_success callback after submission' do
      callback_object.should_receive(:on_success).with(an_instance_of(VaultedBilling::HTTP::Response))
      subject
    end

    it 'runs the on_complete callback after submission' do
      callback_object.should_receive(:on_complete).with(an_instance_of(VaultedBilling::HTTP::Response))
      subject
    end
    
    it 'runs the on_error callback after submission' do
      WebMock.stub_request(:any, url).to_raise(Timeout::Error.new('Test Exception'))
      callback_object.should_receive(:on_error).with(an_instance_of(VaultedBilling::HTTP::Response), an_instance_of(Timeout::Error))
      subject
    end
  end
  
  shared_examples_for "a request with timeout errors" do
    context 'with Timeout errors' do
      before(:each) do
        WebMock.stub_request(:any, url).to_raise(Timeout::Error.new('Test Exception'))
      end

      after(:each) { WebMock.reset! }

      it { should be_kind_of VaultedBilling::HTTP::Response}
      it { should_not be_success }

      it 'returns the error information' do
        subject.message.tap do |message|
          message.should match 'Timeout::Error'
          message.should match 'Test Exception'
        end
      end
    end
  end
  
  shared_examples_for 'a request with a custom user agent' do
    it 'sets the library name' do
      subject
      WebMock.should have_requested(:any, url).with(:headers => {'User-Agent' => /^vaulted_billing\b/})
    end
    
    it 'sets the library version' do
      subject
      WebMock.should have_requested(:any, url).with(:headers => {'User-Agent' => /\b#{Regexp.escape(VaultedBilling::Version)}\b/})
    end
    
    it 'sets the Ruby version' do
      subject
      WebMock.should have_requested(:any, url).with(:headers => {'User-Agent' => /\b#{Regexp.escape(RUBY_VERSION)}\b/})
    end
    
    it 'sets the Ruby platform' do
      subject
      WebMock.should have_requested(:any, url).with(:headers => {'User-Agent' => /\b#{Regexp.escape(RUBY_PLATFORM)}\b/})
    end
  end

  context '#post' do
    subject { http.post('fubar') }

    before(:each) { WebMock.stub_request(:any, url) }

    it 'posts the given data' do
      subject
      WebMock.should have_requested(:post, url).with(:body => 'fubar')
    end

    it_should_behave_like 'a request with a custom user agent'
    it_should_behave_like "a request with callbacks", Net::HTTP::Post
    it_should_behave_like "a request with timeout errors"
  end
  
  context '#get' do
    subject { http.get }

    before(:each) { WebMock.stub_request(:any, url) }

    it 'gets the given url' do
      subject
      WebMock.should have_requested(:get, url)
    end

    it_should_behave_like 'a request with a custom user agent'
    it_should_behave_like "a request with callbacks", Net::HTTP::Get
    it_should_behave_like "a request with timeout errors"
  end
  
  context '#put' do
    subject { http.put('bar') }

    before(:each) { WebMock.stub_request(:any, url) }

    it 'posts the given data' do
      subject
      WebMock.should have_requested(:put, url).with(:body => 'bar')
    end

    it_should_behave_like 'a request with a custom user agent'
    it_should_behave_like "a request with callbacks", Net::HTTP::Put
    it_should_behave_like "a request with timeout errors"
  end
  
  it 'fails over to subsequent URIs with HTTP ERRORs raised' do
    WebMock.stub_request(:any, /.*/).to_timeout
    
    VaultedBilling::HTTP.new(callback_object, ['https://example1.com', 'https://example2.com']).tap do |http|
      http.get
      WebMock.should have_requested(:get, 'https://example1.com/')
      WebMock.should have_requested(:get, 'https://example2.com/')
    end
  end
  
  it 'returns connection error response when all URIs return HTTP ERRORs' do
    WebMock.stub_request(:any, /.*/).to_timeout
    
    VaultedBilling::HTTP.new(callback_object, ['https://example1.com', 'https://example2.com']).tap do |http|
      http.get.should be_connection_error
    end
  end
end
