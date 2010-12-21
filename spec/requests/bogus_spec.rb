require File.expand_path('../../spec_helper', __FILE__)

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

    it { should be_success }
    its(:authcode) { should be_present }
    its(:masked_card_number) { should be_present }
  end

  context 'capture' do
    subject { gateway.capture('transaction_id', 1) }
    it_should_behave_like 'a transaction request'

    it { should be_success }
    its(:masked_card_number) { should be_present }
  end

  context 'purchase' do
    let(:customer) { Factory.build(:existing_customer) }
    let(:credit_card) { Factory.build(:existing_credit_card) }
    subject { gateway.purchase(customer, credit_card, 1) }
    it_should_behave_like 'a transaction request'

    it { should be_success }
    its(:masked_card_number) { should be_present }
  end

  context 'void' do
    subject { gateway.void('transaction_id') }
    it_should_behave_like 'a transaction request'

    it { should be_success }
    its(:masked_card_number) { should be_present }
  end

  context 'refund' do
    subject { gateway.refund('transaction_id', 1) }
    it_should_behave_like 'a transaction request'

    it { should be_success }
    its(:masked_card_number) { should be_present }
  end
end
