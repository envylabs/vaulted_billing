require File.expand_path('../../../spec_helper', __FILE__)

describe VaultedBilling::Transaction do
  subject { VaultedBilling::Transaction.new }

  context 'to_vaulted_billing' do
    it 'returns itself' do
      subject.to_vaulted_billing.should == subject
    end
  end

  context '==' do
    let(:attributes) { {:id => '123', :authcode => 'ABC'} }

    it 'is true for Transactions with identical attributes' do
      VaultedBilling::Transaction.new(attributes).
        should == VaultedBilling::Transaction.new(attributes)
    end

    it 'is false for Transactions with differing attributes' do
      VaultedBilling::Transaction.new(attributes).
        should_not == VaultedBilling::Transaction.
        new(attributes.merge(:authcode => 'BAD'))
    end
  end

  context 'with attributes defined' do
    let(:attributes) do
      { :id => '123',
        :authcode => 'ABC',
        :avs_response => true,
        :cvv_response => true,
        :code => '100',
        :message => 'Test Message',
        :masked_card_number => 'XXXX1234'
      }
    end
    subject { VaultedBilling::Transaction.new(attributes) }

    its(:id) { should == '123' }
    its(:authcode) { should == 'ABC' }
    its(:avs_response) { should be_true }
    its(:cvv_response) { should be_true }
    its(:code) { should == '100' }
    its(:message) { should == 'Test Message' }
    its(:masked_card_number) { should == 'XXXX1234' }
  end

  context 'attributes' do
    subject { VaultedBilling::Transaction.new.attributes }
    it { should be_kind_of Hash }
    its(:keys) { should include :id }
    its(:keys) { should include :authcode }
    its(:keys) { should include :avs_response }
    its(:keys) { should include :cvv_response }
    its(:keys) { should include :code }
    its(:keys) { should include :message }
    its(:keys) { should include :masked_card_number }
  end
end
