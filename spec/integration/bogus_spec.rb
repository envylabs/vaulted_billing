require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe VaultedBilling::Gateways::Bogus do
  let(:gateway) { VaultedBilling::Gateways::Bogus.new }
  let(:customer) { Factory.build(:customer) }
  let(:credit_card) { Factory.build(:credit_card) }

  context 'add_customer' do
    subject { gateway.add_customer(customer) }
    it_should_behave_like 'a customer request'

    it 'is successful' do
      subject.should be_success
    end
  end

  context 'update_customer' do
    let(:customer) { Factory.build(:existing_customer) }
    subject { gateway.update_customer(customer) }
    it_should_behave_like 'a customer request'

    it 'is successful' do
      subject.should be_success
    end
  end

  context 'remove_customer' do
    let(:customer) { Factory.build(:existing_customer) }
    subject { gateway.remove_customer(customer) }
    it_should_behave_like 'a customer request'

    it 'is successful' do
      subject.should be_success
    end
  end

  context 'update_customer_credit_card' do
    let(:customer) { Factory.build(:existing_customer) }
    let(:credit_card) { Factory.build(:existing_credit_card) }
    subject { gateway.update_customer_credit_card(customer, credit_card) }
    it_should_behave_like 'a credit card request'

    it 'is successful' do
      subject.should be_success
    end
  end

  context 'add_customer_credit_card' do
    subject { gateway.add_customer_credit_card(customer, credit_card) }
    it_should_behave_like 'a credit card request'

    it 'is successful' do
      subject.should be_success
    end
  end

  context 'remove_customer_credit_card' do
    let(:customer) { Factory.build(:existing_customer) }
    let(:credit_card) { Factory.build(:existing_credit_card) }
    subject { gateway.remove_customer_credit_card(customer, credit_card) }
    it_should_behave_like 'a credit card request'

    it 'is successful' do
      subject.should be_success
    end
  end

  context 'authorize' do
    let(:customer) { Factory.build(:existing_customer) }
    let(:credit_card) { Factory.build(:existing_credit_card) }
    subject { gateway.authorize(customer, credit_card, 1) }
    it_should_behave_like 'a transaction request'

    it "is successful" do
      subject.should be_success
    end

    it "returns an authcode" do
      subject.authcode.should_not be_nil
    end
  end

  context 'capture' do
    subject { gateway.capture('transaction_id', 1) }
    it_should_behave_like 'a transaction request'

    it "is successful" do
      subject.should be_success
    end
  end

  context 'void' do
    subject { gateway.void('transaction_id') }
    it_should_behave_like 'a transaction request'

    it "is successful" do
      subject.should be_success
    end
  end

  context 'refund' do
    subject { gateway.refund('transaction_id', 1) }
    it_should_behave_like 'a transaction request'

    it "is successful" do
      subject.should be_success
    end
  end
end
