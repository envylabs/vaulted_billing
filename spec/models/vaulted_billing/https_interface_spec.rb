require File.expand_path('../../../spec_helper', __FILE__)

class HttpsInterfaceTestObject
  include VaultedBilling::HttpsInterface

  def initialize(options = {})
    self.test_uri = options[:test_uri]
    self.live_uri = options[:live_uri]
    self.use_test_uri = options[:test]
  end
end

describe VaultedBilling::HttpsInterface do
  it 'uses the live uri by default' do
    HttpsInterfaceTestObject.new(:live_uri => 'https://live.uri').tap do |http|
      http.uri.to_s.should == 'https://live.uri'
    end
  end

  it 'uses the given test uri in test mode' do
    HttpsInterfaceTestObject.new(:test_uri => 'https://test.uri', :test => true).tap do |http|
      http.uri.to_s.should == 'https://test.uri'
    end
  end

  it 'uses the given live uri in live mode' do
    HttpsInterfaceTestObject.new(:live_uri => 'https://live.uri', :test => false).tap do |http|
      http.uri.to_s.should == 'https://live.uri'
    end
  end

  context 'post_data' do
    let(:gateway) { HttpsInterfaceTestObject.new(:live_uri => 'https://1.2.3.4/') }

    before(:each) do
      WebMock.stub_request(:post, 'https://1.2.3.4/')
    end

    after(:each) do
      WebMock.reset!
    end

    it 'posts the given data' do
      gateway.send(:post_data, 'fubar')
      WebMock.should have_requested(:post, 'https://1.2.3.4/').with(:body => 'fubar')
    end

    it 'sets a custom User-Agent header' do
      gateway.send(:post_data, 'fubar')
      WebMock.should have_requested(:post, 'https://1.2.3.4/').with(:headers => {'User-Agent' => "vaulted_billing/#{VaultedBilling::Version}"})
    end

    it 'runs the before_post callback before submission' do
      gateway.should_receive(:before_post).with('fubar').and_raise(RuntimeError)
      expect {
        gateway.send(:post_data, 'fubar')
      }.to raise_error(RuntimeError)
      WebMock.should_not have_requested(:any, 'https://1.2.3.4/')
    end

    it 'runs the after_post callback after submission' do
      gateway.should_receive(:after_post).with(an_instance_of(VaultedBilling::HttpsInterface::PostResponse))
      gateway.send(:post_data, 'fubar')
    end

    context 'with Timeout errors' do
      before(:each) do
        WebMock.stub_request(:post, 'https://1.2.3.4/').to_raise(Timeout::Error.new('Test Exception'))
      end

      after(:each) do
        WebMock.reset!
      end

      it 'returns an PostResponse' do
        gateway.send(:post_data, 'fubar').should be_kind_of VaultedBilling::HttpsInterface::PostResponse
      end

      it 'is unsuccessful' do
        gateway.send(:post_data, 'fubar').should_not be_success
      end

      it 'returns the error information' do
        gateway.send(:post_data, 'fubar').message.tap do |message|
          message.should match 'Timeout::Error'
          message.should match 'Test Exception'
        end
      end
    end
  end
end
