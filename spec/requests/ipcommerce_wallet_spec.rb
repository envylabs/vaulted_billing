require 'spec_helper'

describe VaultedBilling::Gateways::IpcommerceWallet do
  let(:gateway) { VaultedBilling.gateway(:ipcommerce_wallet).new }

  it { should be_a VaultedBilling::Gateway }

  shared_examples_for 'a no-op' do |expected_return_class|
    it { should be_success }
    it { should be_a expected_return_class }

    it 'does not make a service request' do
      expect { subject }.
        to_not raise_error(WebMock::NetConnectNotAllowedError)
    end
  end

  context '#add_customer' do
    let(:customer) { Factory.build(:customer) }
    subject { gateway.add_customer(customer) }
    it_should_behave_like 'a no-op', VaultedBilling::Customer
  end

  context '#add_customer_credit_card' do
    let(:customer) { Factory.build(:customer) }
    let(:credit_card) { Factory.build(:credit_card) }
    subject { gateway.add_customer_credit_card(customer, credit_card) }
    it_should_behave_like 'a no-op', VaultedBilling::CreditCard
  end

  context '#remove_customer' do
    let(:customer) { gateway.add_customer(Factory.build(:customer)) }
    subject { gateway.remove_customer(customer) }
    it_should_behave_like 'a no-op', VaultedBilling::Customer
  end

  context '#remove_customer_credit_card' do
    let(:customer) { Factory.build(:customer) }
    let(:credit_card) { Factory.build(:credit_card) }
    subject { gateway.remove_customer_credit_card(customer, credit_card) }
    it_should_behave_like 'a no-op', VaultedBilling::CreditCard
  end

  context '#update_customer' do
    let(:customer) { gateway.add_customer(Factory.build(:customer)) }
    subject { gateway.update_customer(customer) }
    it_should_behave_like 'a no-op', VaultedBilling::Customer
  end

  context '#update_customer_credit_card' do
    let(:customer) { Factory.build(:customer) }
    let(:credit_card) { Factory.build(:credit_card) }
    subject { gateway.update_customer_credit_card(customer, credit_card) }
    it_should_behave_like 'a no-op', VaultedBilling::CreditCard
  end

  context '#authorize' do
    let(:customer) { gateway.add_customer Factory.build(:customer) }
    let(:credit_card) { gateway.add_customer_credit_card customer, Factory.build(:credit_card) }
    subject { gateway.authorize(customer, credit_card, 1.00) }

    context 'when successful' do
      it_should_behave_like 'a transaction request'
    end

    context 'with a failure' do
      pending
    end
  end
end
