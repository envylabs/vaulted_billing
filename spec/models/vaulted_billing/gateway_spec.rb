require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

class TestGateway
  include VaultedBilling::Gateway
end

class TestResponseObject
  include VaultedBilling::Gateway::Response
end

describe VaultedBilling::Gateway do
  let(:gateway) { TestGateway.new }
  let(:customer) { Factory.build(:customer) }
  let(:credit_card) { Factory.build(:credit_card) }

  subject { gateway }

  context 'add_customer' do
    it 'raises NotImplementedError' do
      expect { gateway.add_customer(customer) }.to raise_error(NotImplementedError)
    end
  end

  context 'update_customer' do
    it 'raises NotImplementedError' do
      expect { gateway.update_customer(customer) }.to raise_error(NotImplementedError)
    end
  end

  context 'remove_customer' do
    it 'raises NotImplementedError' do
      expect { gateway.remove_customer(customer) }.to raise_error(NotImplementedError)
    end
  end

  context 'add_customer_credit_card' do
    it 'raises NotImplementedError' do
      expect { gateway.add_customer_credit_card(customer, credit_card) }.to raise_error(NotImplementedError)
    end
  end

  context 'update_customer_credit_card' do
    it 'raises NotImplementedError' do
      expect { gateway.update_customer_credit_card(customer, credit_card) }.to raise_error(NotImplementedError)
    end
  end

  context 'remove_customer_credit_card' do
    it 'raises NotImplementedError' do
      expect { gateway.remove_customer_credit_card(customer, credit_card) }.to raise_error(NotImplementedError)
    end
  end

  context 'authorize' do
    it 'raises NotImplementedError' do
      expect { gateway.authorize(customer, credit_card, 1) }.to raise_error(NotImplementedError)
    end
  end

  context 'capture' do
    it 'raises NotImplementedError' do
      expect { gateway.capture('transactionid', 1) }.to raise_error(NotImplementedError)
    end
  end

  context 'purchase' do
    it 'raises NotImplementedError' do
      expect { gateway.purchase(customer, credit_card, 1) }.to raise_error(NotImplementedError)
    end
  end

  context 'refund' do
    it 'raises NotImplementedError' do
      expect { gateway.refund('transactionid', 1) }.to raise_error(NotImplementedError)
    end
  end

  context 'void' do
    it 'raises NotImplementedError' do
      expect { gateway.void('transactionid') }.to raise_error(NotImplementedError)
    end
  end
end

describe VaultedBilling::Gateway::Response do
  subject { TestResponseObject.new }

  it 'returns the set response_message' do
    expect {
      subject.response_message = 'test'
      subject.response_message.should == 'test'
    }.to_not raise_error(NoMethodError)
  end

  it 'returns the set raw_response' do
    expect {
      subject.raw_response = 'test'
      subject.raw_response.should == 'test'
    }.to_not raise_error(NoMethodError)
  end

  it 'returns the set error_code' do
    expect {
      subject.error_code = 'test'
      subject.error_code.should == 'test'
    }.to_not raise_error(NoMethodError)
  end

  it 'sets the success state' do
    expect {
      subject.success = true
      subject.should be_success
    }.to_not raise_error(NoMethodError)
  end
end
