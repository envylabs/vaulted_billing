require File.expand_path('../../spec_helper', __FILE__)

describe VaultedBilling::Gateways::NmiCustomerVault do
  let(:gateway) { VaultedBilling.gateway(:nmi_customer_vault).new(:username => 'demo', :password => 'password') }

  it 'uses the correct URI in test mode' do
    gateway.use_test_uri = true
    gateway.uri.to_s.should == 'https://secure.nmi.com/api/transact.php'
  end

  it 'uses the correct URI in live mode' do
    gateway.use_test_uri = false
    gateway.uri.to_s.should == 'https://secure.nmi.com/api/transact.php'
  end

  context 'add_customer' do
    let(:customer) { Factory.build(:customer) }
    subject { gateway.add_customer(customer) }

    it 'returns a Customer' do
      subject.should be_kind_of VaultedBilling::Customer
    end

    it 'is successful' do
      subject.should be_success
    end

    it 'does not make a service request' do
      WebMock.should_not have_requested(:post, gateway.uri.to_s)
    end
  end

  context 'update_customer' do
    let(:customer) { gateway.add_customer(Factory.build(:customer)) }
    subject { gateway.update_customer(customer) }

    it 'returns a Customer' do
      subject.should be_kind_of VaultedBilling::Customer
    end

    it 'is successful' do
      subject.should be_success
    end

    it 'does not make a service request' do
      WebMock.should_not have_requested(:post, gateway.uri.to_s)
    end
  end

  context 'remove_customer' do
    let(:customer) { gateway.add_customer(Factory.build(:customer)) }
    subject { gateway.remove_customer(customer) }

    it 'returns a Customer' do
      subject.should be_kind_of VaultedBilling::Customer
    end

    it 'is successful' do
      subject.should be_success
    end

    it 'does not make a service request' do
      WebMock.should_not have_requested(:post, gateway.uri.to_s)
    end
  end

  context 'add_customer_credit_card' do
    let(:customer) { gateway.add_customer(Factory.build(:customer)) }
    let(:credit_card) { Factory.build(:credit_card) }

    cached_request_context 'with a successful result',
      :scope => 'nmi_customer_vault_add_customer_credit_card_success' do
      subject { gateway.add_customer_credit_card(customer, credit_card) }
      it_should_behave_like 'a credit card request'

      it 'is successful' do
        subject.should be_success
      end

      its(:response_message) { should == 'Customer Added' }
      its(:error_code) { should be_nil }
    end

    cached_request_context 'with an unsuccessful result',
      :scope => 'nmi_customer_vault_add_customer_credit_card_failure' do
      let(:credit_card) { Factory.build(:credit_card, :card_number => nil) }
      subject { gateway.add_customer_credit_card(customer, credit_card) }

      it 'returns a CreditCard' do
        subject.should be_kind_of VaultedBilling::CreditCard
      end

      it 'is unsuccessful' do
        subject.should_not be_success
      end

      its(:response_message) { should == 'Required Field cc_number is Missing or Empty REFID:109525605' }
      its(:error_code) { should == '300' }
    end

    request_exception_context do
      let(:credit_card) { Factory.build(:credit_card, :card_number => nil) }
      subject { gateway.add_customer_credit_card(customer, credit_card) }
      it_should_behave_like 'a failed connection attempt'
    end
  end

  context 'update_customer_credit_card' do
    let(:customer) { gateway.add_customer(Factory.build(:customer)) }
    let(:credit_card) { gateway.add_customer_credit_card(customer, Factory.build(:credit_card)) }

    cached_request_context 'with a successful result', 
      :scope => 'nmi_customer_vault_update_customer_credit_card_success' do
      subject { gateway.update_customer_credit_card(customer, credit_card) }
      it_should_behave_like 'a credit card request'

      it 'is successful' do
        should be_success
      end
    end

    cached_request_context 'with an unsuccessful result',
      :scope => 'nmi_customer_vault_update_customer_credit_card_failure' do
      before(:each) { pending "The NMI Customer Vault currently *always* returns a successful response, even with obviously invalid data." }
      let(:customer) { VaultedBilling::Customer.new }
      let(:credit_card) { VaultedBilling::CreditCard.new }
      subject { gateway.update_customer_credit_card(customer, credit_card) }
      it_should_behave_like 'a credit card request'

      it 'is unsuccessful' do
        should_not be_success
      end
    end

    request_exception_context do
      let(:customer) { VaultedBilling::Customer.new }
      let(:credit_card) { VaultedBilling::CreditCard.new }
      subject { gateway.update_customer_credit_card(customer, credit_card) }
      it_should_behave_like 'a failed connection attempt'
    end
  end

  context 'remove_customer_credit_card' do
    let(:customer) { gateway.add_customer(Factory.build(:customer)) }
    let(:credit_card) { gateway.add_customer_credit_card(customer, Factory.build(:credit_card)) }

    cached_request_context 'with a successful result',
     :scope => 'nmi_customer_vault_remove_customer_credit_card_success' do
      subject { gateway.remove_customer_credit_card(customer, credit_card) }
      it_should_behave_like 'a credit card request'

      it 'is successful' do
        should be_success
      end
    end

    cached_request_context 'with an unsuccessful result',
     :scope => 'nmi_customer_vault_remove_customer_credit_card_failure' do
      let(:credit_card) { Factory.build(:existing_credit_card, :vault_id => 'VERYBADIDENTIFIER!') }
      subject { gateway.remove_customer_credit_card(customer, credit_card) }
      it_should_behave_like 'a credit card request'

      it 'is unsuccessful' do
        should_not be_success
      end
    end

    request_exception_context do
      let(:credit_card) { Factory.build(:existing_credit_card, :vault_id => 'VERYBADIDENTIFIER!') }
      subject { gateway.remove_customer_credit_card(customer, credit_card) }
      it_should_behave_like 'a failed connection attempt'
    end
  end

  context 'purchase' do
    let(:customer) { gateway.add_customer(Factory.build(:customer)) }
    let(:credit_card) { gateway.add_customer_credit_card(customer, Factory.build(:credit_card)) }

    cached_request_context 'with a successful result',
      :scope => 'nmi_customer_vault_purchase_success' do
      subject { gateway.purchase(customer, credit_card, 1.00) }
      it_should_behave_like 'a transaction request'

      it 'is successful' do
        should be_success
      end

      it('has an false AVS response') { subject.avs_response.should be_false }
      it('has a false CVV response') { subject.cvv_response.should be_false }
      it('has an authcode') { subject.authcode.should be_present }
      it('has a message') { subject.message.should be_present }
      it('has a response code') { subject.code.should be_present }
    end

    cached_request_context 'with an DECLINE result',
      :scope => 'nmi_customer_vault_purchase_decline' do
      subject { gateway.purchase(customer, credit_card, 0.01) }
      it_should_behave_like 'a transaction request'

      it 'is unsuccessful' do
        should_not be_success
      end
    end

    request_exception_context do
      subject { gateway.purchase(customer, credit_card, 0.01) }
      it_should_behave_like 'a failed connection attempt'
    end
  end

  context 'authorize' do
    let(:customer) { gateway.add_customer(Factory.build(:customer)) }
    let(:credit_card) { gateway.add_customer_credit_card(customer, Factory.build(:credit_card)) }

    cached_request_context 'with a successful result',
      :scope => 'nmi_customer_vault_authorize_success' do
      subject { gateway.authorize(customer, credit_card, 1.00) }
      it_should_behave_like 'a transaction request'

      it 'is successful' do
        should be_success
      end

      it('has an false AVS response') { subject.avs_response.should be_false }
      it('has a false CVV response') { subject.cvv_response.should be_false }
      it('has an authcode') { subject.authcode.should be_present }
      it('has a message') { subject.message.should be_present }
      it('has a response code') { subject.code.should be_present }
    end

    cached_request_context 'with an DECLINE result',
      :scope => 'nmi_customer_vault_authorize_decline' do
      subject { gateway.authorize(customer, credit_card, 0.01) }
      it_should_behave_like 'a transaction request'

      it 'is unsuccessful' do
        should_not be_success
      end
    end

    request_exception_context do
      subject { gateway.authorize(customer, credit_card, 0.01) }
      it_should_behave_like 'a failed connection attempt'
    end
  end

  context 'capture' do
    let(:customer) { gateway.add_customer(Factory.build(:customer)) }
    let(:credit_card) { gateway.add_customer_credit_card(customer, Factory.build(:credit_card)) }
    let(:authorization) { gateway.authorize(customer, credit_card, 10.00) }

    cached_request_context 'with a successful result',
      :scope => 'nmi_customer_vault_capture_success' do
      let(:capture) { gateway.capture(authorization.id, 5.00) }
      subject { capture }
      it_should_behave_like 'a transaction request'

      it 'is successful' do
        should be_success
      end
    end

    cached_request_context 'with a DECLINE result',
      :scope => 'nmi_customer_vault_capture_failure' do
      let(:capture) { gateway.capture(authorization.id, 500.00) }
      subject { capture }
      it_should_behave_like 'a transaction request'

      it 'is unsuccessful' do
        should_not be_success
      end
    end

    request_exception_context do
      let(:capture) { gateway.capture(authorization.id, 500.00) }
      subject { capture }
      it_should_behave_like 'a failed connection attempt'
    end
  end

  context 'refund' do
    let(:customer) { gateway.add_customer(Factory.build(:customer)) }
    let(:credit_card) { gateway.add_customer_credit_card(customer, Factory.build(:credit_card)) }
    let(:authorization) { gateway.authorize(customer, credit_card, 5.00) }
    let(:capture) { gateway.capture(authorization.id, 3.00) }

    cached_request_context 'with a successful result',
      :scope => 'nmi_customer_vault_refund_success' do
      let(:refund) { gateway.refund(capture.id, 3.00) }
      before(:each) do
        pending 'Does not appear to allow me to immediately refund a capture'
      end
      subject { refund }
      it_should_behave_like 'a transaction request'

      it 'is successful' do
        should be_success
      end
    end

    cached_request_context 'with a DECLINE result',
      :scope => 'nmi_customer_vault_refund_failure' do
      let(:refund) { gateway.refund(capture.id, 300.00) }
      subject { refund }

      it 'returns a Transaction' do
        subject.should be_kind_of VaultedBilling::Transaction
      end

      it 'returns a Transaction without an identifier' do
        subject.id.should be_blank
      end

      it 'is unsuccessful' do
        should_not be_success
      end
    end

    request_exception_context do
      let(:refund) { gateway.refund(capture.id, 300.00) }
      subject { refund }
      it_should_behave_like 'a failed connection attempt'
    end
  end

  context 'void' do
    let(:customer) { gateway.add_customer(Factory.build(:customer)) }
    let(:credit_card) { gateway.add_customer_credit_card(customer, Factory.build(:credit_card)) }
    let(:authorization) { gateway.authorize(customer, credit_card, 5.00) }

    cached_request_context 'with a successful result',
      :scope => 'nmi_customer_vault_void_success' do
      let(:void) { gateway.void(authorization.id) }
      subject { void }
      it_should_behave_like 'a transaction request'

      it 'is successful' do
        should be_success
      end
    end

    cached_request_context 'with a DECLINE result',
      :scope => 'nmi_customer_vault_void_failure' do
      let(:void) { gateway.void('INVALIDID') }
      subject { void }

      it 'returns a Transaction' do
        subject.should be_kind_of VaultedBilling::Transaction
      end

      it 'returns a Transaction without an identifier' do
        subject.id.should be_blank
      end

      it 'is unsuccessful' do
        should_not be_success
      end
    end

    request_exception_context do
      let(:void) { gateway.void('INVALIDID') }
      subject { void }
      it_should_behave_like 'a failed connection attempt'
    end
  end
end
