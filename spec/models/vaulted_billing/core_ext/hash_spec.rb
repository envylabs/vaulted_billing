require File.expand_path(File.join(File.dirname(__FILE__), '..', '..', '..', 'spec_helper'))

describe VaultedBilling::CoreExt::Hash do
  context 'to_querystring' do
    it 'converts an empty hash' do
      {}.to_querystring.should == ''
    end

    it 'converts a one key hash' do
      {'foo' => 'bar' }.to_querystring.should == 'foo=bar'
    end

    it 'converts numeric keys' do
      {1 => 2}.to_querystring.should == '1=2'
    end

    it 'converts multi-key hashes' do
      {'foo' => 'bar', 'faz' => 'baz'}.to_querystring.should == 'faz=baz&foo=bar'
    end

    it 'sorts by key name' do
      {'z' => 1, 'y' => 1, 'a' => 1}.to_querystring.should == 'a=1&y=1&z=1'
    end
  end

  context 'from_querystring' do
    it 'converts an empty string' do
      Hash.from_querystring('').should == Hash.new
    end

    it 'converts a one key string' do
      Hash.from_querystring('foo=bar').should == {'foo' => 'bar'}
    end

    it 'converts a multi-key string' do
      Hash.from_querystring('foo=bar&faz=baz').should == {'foo' => 'bar', 'faz' => 'baz'}
    end

    it 'returns empty strings for no-value keys' do
      Hash.from_querystring('foo=&bar=').should == {'foo' => '', 'bar' => ''}
    end

    it 'returns an empty hash with a nil value given' do
      Hash.from_querystring(nil).should == {}
    end
  end
end
