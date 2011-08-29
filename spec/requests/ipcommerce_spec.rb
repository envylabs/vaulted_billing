require 'spec_helper'

describe VaultedBilling::Gateways::Ipcommerce do
  let(:gateway) { VaultedBilling.gateway(:ipcommerce).new }
  let(:merchant_profile_id) { 'TicketTest_E4FB800001' }

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
    subject { gateway.add_customer_credit_card(customer, credit_card, { :merchant_profile_id => merchant_profile_id }) }

    context 'when successful' do
      let(:credit_card) { gateway.add_customer_credit_card customer, Factory.build(:ipcommerce_credit_card) }
      use_vcr_cassette 'ipcommerce/add_customer_credit_card/success'

      it_should_behave_like 'a credit card request'
      it { should be_success }
    end

    context 'with a failure' do
      let(:credit_card) { Factory.build(:invalid_credit_card) }
      use_vcr_cassette 'ipcommerce/add_customer_credit_card/failure'

      it { should be_a VaultedBilling::CreditCard }
      it { should_not be_success }
      its(:vault_id) { should be_nil }
    end
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

    let(:customer) { Factory.build(:customer) }
    subject { gateway.add_customer_credit_card(customer, credit_card, { :merchant_profile_id => merchant_profile_id }) }

    context 'when successful' do
      let(:credit_card) { gateway.add_customer_credit_card customer, Factory.build(:ipcommerce_credit_card) }
      use_vcr_cassette 'ipcommerce/update_customer_credit_card/success'

      it_should_behave_like 'a credit card request'
      it { should be_success }
    end

    context 'with a failure' do
      let(:credit_card) { Factory.build(:invalid_credit_card) }
      use_vcr_cassette 'ipcommerce/update_customer_credit_card/failure'

      it { should be_a VaultedBilling::CreditCard }
      it { should_not be_success }
      its(:vault_id) { should be_nil }
    end
  end

  context '#authorize' do
    let(:customer) { gateway.add_customer Factory.build(:customer) }
    subject { gateway.authorize(customer, credit_card, 11.00, { :merchant_profile_id => merchant_profile_id }) }

    context 'with a new credit card' do
      context 'when successful' do
        use_vcr_cassette 'ipcommerce/authorize/new/success'
        let(:credit_card) { Factory.build(:ipcommerce_credit_card) }

        it_should_behave_like 'a transaction request'
        it { should be_success }
        its(:id) { should_not be_nil }
        its(:masked_card_number) { should be_present }
        its(:authcode) { should_not be_nil }
        its(:message) { should == "APPROVED" }
        its(:code) { should == 1 }
      end

      context 'with a failure' do
        let(:credit_card) { Factory.build(:invalid_credit_card) }
        use_vcr_cassette 'ipcommerce/authorize/new/failure'

        it_should_behave_like 'a transaction request'
        it { should_not be_success }
        its(:message) { should_not == "APPROVED" }
      end
    end

    context 'with a credit card on file' do
      let(:credit_card) { gateway.add_customer_credit_card customer, Factory.build(:ipcommerce_credit_card) }

      context 'when successful' do
        use_vcr_cassette 'ipcommerce/authorize/existing/success'
        let(:credit_card) { gateway.add_customer_credit_card(customer, Factory.build(:ipcommerce_credit_card), { :merchant_profile_id => merchant_profile_id }) }

        it_should_behave_like 'a transaction request'
        it { should be_success }
        its(:id) { should_not be_nil }
        its(:masked_card_number) { should_not be_present }
        its(:authcode) { should_not be_nil }
        its(:message) { should == "APPROVED" }
        its(:code) { should == 1 }
      end

      context 'with a failure' do
        use_vcr_cassette 'ipcommerce/authorize/existing/failure'
        let(:credit_card) { Factory.build(:ipcommerce_credit_card, :vault_id => "incorrect") }
        it { should be_kind_of(VaultedBilling::Transaction) }
        it { should_not be_success }
        its(:message) { should_not == "APPROVED" }
      end
    end
  end

  context '#capture' do
    let(:amount) { 11.00 }
    let(:customer) { Factory.build(:customer) }
    let(:credit_card) { Factory.build(:ipcommerce_credit_card) }
    let(:authorization) { gateway.authorize(customer, credit_card, 11.00, { :merchant_profile_id => merchant_profile_id }) }

    context 'when successful' do
      subject { gateway.capture(authorization.id, amount)}
      use_vcr_cassette 'ipcommerce/capture/success'

      it_should_behave_like 'a transaction request'
      it { should be_success }
      its(:id) { should_not be_nil }
      its(:authcode) { should be_nil }
      its(:message) { should == "APPROVED" }
      its(:code) { should == 1 }
    end

    context 'with an invalid request' do
      subject { gateway.capture(authorization.id + "t", amount)}
      use_vcr_cassette 'ipcommerce/capture/invalid'

      it { should be_a VaultedBilling::Transaction }
      it { should_not be_success }
      its(:message) { should =~ /^Unable to retrieve serialized transaction for transactionId: .+/ }
    end

    context 'with a failure' do
      subject { gateway.capture(authorization.id, amount * -1)}
      use_vcr_cassette 'ipcommerce/capture/failure'

      it { should be_a VaultedBilling::Transaction }
      it { should_not be_success }
      its(:message) { should =~ /^Amount must be a minimum of 1 and a maximum of 10 numbers followed by a decimal point and exactly 2 decimal places/mi }
    end
  end

  context '#purchase' do
    let(:customer) { gateway.add_customer Factory.build(:customer) }
    subject { gateway.purchase(customer, credit_card, 10.00, { :merchant_profile_id => merchant_profile_id }) }

    context 'with a new credit card' do
      context 'when successful' do
        use_vcr_cassette 'ipcommerce/purchase/new/success'
        let(:credit_card) { Factory.build(:ipcommerce_credit_card) }

        it_should_behave_like 'a transaction request'
        it { should be_success }
        its(:id) { should_not be_nil }
        its(:authcode) { should_not be_nil }
        its(:message) { should == "APPROVED" }
        its(:code) { should == 1 }
      end

      context 'with a failure' do
        use_vcr_cassette 'ipcommerce/purchase/new/failure'
        let(:credit_card) { Factory.build(:invalid_credit_card) }

        it_should_behave_like 'a transaction request'
        it { should_not be_success }
        its(:message) { should_not == "APPROVED" }
      end
    end

    context 'with a credit card on file' do
      let(:credit_card) { gateway.add_customer_credit_card customer, Factory.build(:ipcommerce_credit_card) }

      context 'when successful' do
        use_vcr_cassette 'ipcommerce/purchase/existing/success'
        let(:credit_card) { gateway.add_customer_credit_card(customer, Factory.build(:ipcommerce_credit_card), { :merchant_profile_id => merchant_profile_id }) }

        it_should_behave_like 'a transaction request'
        it { should be_success }
        its(:id) { should_not be_nil }
        its(:masked_card_number) { should_not be_present }
        its(:authcode) { should_not be_nil }
        its(:message) { should == "APPROVED" }
        its(:code) { should == 1 }
      end

      context 'with a failure' do
        use_vcr_cassette 'ipcommerce/purchase/existing/failure'
        let(:credit_card) { Factory.build(:ipcommerce_credit_card, :vault_id => "incorrect") }
        it { should be_kind_of(VaultedBilling::Transaction) }
        it { should_not be_success }
        its(:message) { should_not == "APPROVED" }
      end
    end

  end

  # Returning funds from a captured transaction
  context '#refund' do
    let(:amount) { 5.00 }
    let(:customer) { Factory.build(:customer) }
    let(:credit_card) { Factory.build(:ipcommerce_credit_card) }
    let(:purchase) { gateway.purchase(customer, credit_card, amount, { :merchant_profile_id => merchant_profile_id }) }

    context 'with a successful result' do
      subject { gateway.refund(purchase.id, amount) }
      use_vcr_cassette 'ipcommerce/refund/success'

      it_should_behave_like 'a transaction request'
      it { should be_success }
      its(:id) { should_not be_nil }
      its(:authcode) { should_not be_nil }
      its(:message) { should == "APPROVED" }
      its(:code) { should == 1 }
    end

    context 'with a failure' do
      subject { gateway.refund(purchase.id, amount + 1) }
      use_vcr_cassette 'ipcommerce/refund/failure'

      it { should be_a VaultedBilling::Transaction }
      it { should_not be_success }
      its(:message) { should == "Attempt to return more than original authorization." }
      its(:code) { should eql '326' }
    end
  end

  # Releasing funds from an authorized but uncaptured transaction
  context '#void' do
    let(:customer) { gateway.add_customer(Factory.build(:customer)) }
    let(:credit_card) { Factory.build(:ipcommerce_credit_card) }
    let(:authorization) { gateway.authorize(customer, credit_card, 5.00, { :merchant_profile_id => merchant_profile_id }) }

    context 'with a successful result' do
      subject { gateway.void(authorization.id, { :merchant_profile_id => merchant_profile_id, :credit_card => credit_card }) }
      use_vcr_cassette 'ipcommerce/void/success'

      it_should_behave_like 'a transaction request'
      it { should be_success }
      its(:id) { should_not be_nil }
      its(:authcode) { should_not be_nil }
      its(:message) { should == "APPROVED" }
      its(:code) { should == 1 }
    end

    context 'with a failure' do
      subject { gateway.void(authorization.id + "_bad", { :merchant_profile_id => merchant_profile_id, :credit_card => credit_card }) }
      use_vcr_cassette 'ipcommerce/void/failure'

      it { should be_a VaultedBilling::Transaction }
      it { should_not be_success }
      its(:message) { should =~ /^Unable to retrieve serialized transaction for transactionId: .+/ }
    end
  end

  it 'fails over to secondary end point with a connection error on the first' do
    VCR.use_cassette('ipcommerce/failover') do
      WebMock.stub_request(:any, %r{^https://.*?@cws-01\.cert\.ipcommerce\.com/}).to_timeout
      customer = Factory.build(:customer)
      credit_card = Factory.build(:ipcommerce_credit_card)
      result = gateway.authorize(customer, credit_card, 11.00, { :merchant_profile_id => merchant_profile_id })
      result.should be_success
    end
    WebMock.should have_requested(:get, %r{^https://.*?@cws-02\.cert\.ipcommerce\.com/})
  end

  it 'raises an UnavailableKeyError when a session key cannot be acquired' do
    WebMock.stub_request(:any, /.*/).to_timeout
    expect {
      customer = gateway.add_customer Factory.build(:customer)
      credit_card = gateway.add_customer_credit_card customer, Factory.build(:ipcommerce_credit_card)
      result = gateway.authorize(customer, credit_card, 11.00, { :merchant_profile_id => merchant_profile_id })
    }.to raise_error(VaultedBilling::Gateways::Ipcommerce::ServiceKeyStore::UnavailableKeyError)
  end
end
