require File.expand_path('../../../spec_helper', __FILE__)

class CallerObject
  def before_request(request); end
  def on_complete(response); end
  def on_success(response); end
  def on_error(response, error); end
end

describe VaultedBilling::HTTP do
  let(:gateway) { VaultedBilling::HTTP.new(callback_object, url, {
    :before_request => :before_request,
    :on_complete => :on_complete,
    :on_success => :on_success,
    :on_error => :on_error
  }) }

  let(:callback_object) { CallerObject.new }

  let(:url) { 'https://1.2.3.4/' }
  
  after(:each) { WebMock.reset! }

  shared_examples_for "a request with callbacks"  do |net_request, method|
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
      WebMock.stub_request(method, url).to_raise(Timeout::Error.new('Test Exception'))
      callback_object.should_receive(:on_error).with(an_instance_of(VaultedBilling::HTTP::Response), an_instance_of(Timeout::Error))
      subject
    end
  end
  
  shared_examples_for "a request with timeout errors" do |method|
    context 'with Timeout errors' do
      before(:each) do
        WebMock.stub_request(method, url).to_raise(Timeout::Error.new('Test Exception'))
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

  context '#post' do
    subject { gateway.post('fubar') }

    before(:each) { WebMock.stub_request(:post, url) }

    it 'posts the given data' do
      subject
      WebMock.should have_requested(:post, url).with(:body => 'fubar')
    end

    it 'sets a custom User-Agent header' do
      subject
      WebMock.should have_requested(:post, url).with(:headers => {'User-Agent' => "vaulted_billing/#{VaultedBilling::Version}"})
    end

    it_should_behave_like "a request with callbacks", Net::HTTP::Post, :post
    it_should_behave_like "a request with timeout errors", :post
  end
  
  context '#get' do
    subject { gateway.get }

    before(:each) { WebMock.stub_request(:get, url) }

    it 'gets the given url' do
      subject
      WebMock.should have_requested(:get, url)
    end

    it 'sets a custom User-Agent header' do
      subject
      WebMock.should have_requested(:get, url).with(:headers => {'User-Agent' => "vaulted_billing/#{VaultedBilling::Version}"})
    end

    it_should_behave_like "a request with callbacks", Net::HTTP::Get, :get
    it_should_behave_like "a request with timeout errors", :get
  end
  
  context '#put' do
    subject { gateway.put('bar') }

    before(:each) { WebMock.stub_request(:put, url) }

    it 'posts the given data' do
      subject
      WebMock.should have_requested(:put, url).with(:body => 'bar')
    end

    it 'sets a custom User-Agent header' do
      subject
      WebMock.should have_requested(:put, url).with(:headers => {'User-Agent' => "vaulted_billing/#{VaultedBilling::Version}"})
    end

    it_should_behave_like "a request with callbacks", Net::HTTP::Put, :put
    it_should_behave_like "a request with timeout errors", :put
  end
end
