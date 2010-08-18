require 'spec_helper'

describe VaultedBilling::Gateways::Bogus do
  let(:gateway) { VaultedBilling::Gateways::Bogus.new }
  let(:customer) { Factory.build(:customer) }
  let(:credit_card) { Factory.build(:credit_card) }

  context 'add_customer' do
    it 'successfully adds a customer' do
      gateway.add_customer(customer).should be_success
    end

    it 'returns a Gateway::Response' do
      gateway.add_customer(customer).should be_kind_of(VaultedBilling::Gateway::Response)
    end

    it 'returns a Customer result' do
      gateway.add_customer(customer).result.should be_kind_of(VaultedBilling::Customer)
    end

    it 'returns a Customer result with an identifier' do
      gateway.add_customer(customer).result.id.should_not be_blank
    end
  end

  context 'update_customer' do
    it 'successfully updates a customer' do
      gateway.update_customer(customer).should be_success
    end

    it 'returns a Gateway::Response' do
      gateway.update_customer(customer).should be_kind_of(VaultedBilling::Gateway::Response)
    end

    it 'returns a Customer result' do
      gateway.update_customer(customer).result.should be_kind_of(VaultedBilling::Customer)
    end

    it 'returns a Customer result with matching identifier' do
      original_id = customer.id.dup
      gateway.update_customer(customer).result.id.should == original_id
    end
  end

  context 'remove_customer' do
    it 'successfully removes a customer' do
      gateway.remove_customer(customer).should be_success
    end

    it 'returns a Gateway::Response' do
      gateway.remove_customer(customer).should be_kind_of(VaultedBilling::Gateway::Response)
    end

    it 'returns a Customer' do
      gateway.remove_customer(customer).result.should be_kind_of(VaultedBilling::Customer)
    end

    it 'returns the Customer provided' do
      gateway.remove_customer(customer).result.should == customer
    end
  end

  context 'update_customer_credit_card' do
    it "successfully updates the credit card" do
      gateway.update_customer_credit_card(customer, credit_card).should be_success
    end

    it "returns a Gateway::Response" do
      gateway.update_customer_credit_card(customer, credit_card).should be_kind_of(VaultedBilling::Gateway::Response)
    end

    it 'returns a CreditCard result' do
      gateway.update_customer_credit_card(customer, credit_card).result.should be_kind_of(VaultedBilling::CreditCard)
    end

    it "return a CreditCard with matching identifier" do
      original_id = credit_card.id
      gateway.update_customer_credit_card(customer, credit_card).result.id.should == original_id
    end
  end

  context 'add_customer_credit_card' do
    it "successfully adds the credit card" do
      gateway.add_customer_credit_card(customer, credit_card).should be_success
    end

    it "returns a Gateway::Response" do
      gateway.add_customer_credit_card(customer, credit_card).should be_kind_of(VaultedBilling::Gateway::Response)
    end

    it 'returns a CreditCard result' do
      gateway.add_customer_credit_card(customer, credit_card).result.should be_kind_of(VaultedBilling::CreditCard)
    end

    it "returns a CreditCard with an identifier" do
      gateway.add_customer_credit_card(customer, credit_card).result.id.should_not be_blank
    end
  end

  context 'remove_customer_credit_card' do
    it "successfully remove the credit card" do
      gateway.remove_customer_credit_card(customer, credit_card).should_not be_blank
    end

    it "returns a Gateway::Response" do
      gateway.remove_customer_credit_card(customer, credit_card).should be_kind_of(VaultedBilling::Gateway::Response)
    end

    it 'returns a CreditCard result' do
      gateway.remove_customer_credit_card(customer, credit_card).result.should be_kind_of(VaultedBilling::CreditCard)
    end

    it "returns the CreditCard provided" do
      gateway.remove_customer_credit_card(customer, credit_card).result.should == credit_card
    end
  end

  context 'authorize' do
    subject { gateway.authorize(customer, credit_card, 1) }
    it_should_behave_like 'a transaction request'

    it "is successful" do
      subject.should be_success
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
