require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe VaultedBilling::Gateways::NmiCustomerVault do
  let(:gateway) { VaultedBilling::Gateways::NmiCustomerVault.new(:username => 'demo', :password => 'password') }
  let(:customer) { Factory.build(:customer) }
  let(:credit_card) { Factory.build(:credit_card) }

  context 'add_customer' do
    subject { gateway.add_customer(customer) }
    it_should_behave_like 'a customer request'

    it 'is successful' do
      subject.should be_success
    end

    it 'does not make a service request' do
      WebMock.should_not have_requested(:post, gateway.uri.to_s)
    end
  end

  context 'update_customer' do
    let(:customer) { Factory.build(:existing_customer) }
    subject { gateway.update_customer(customer) }
    it_should_behave_like 'a customer request'

    it 'is successful' do
      subject.should be_success
    end

    it 'does not make a service request' do
      WebMock.should_not have_requested(:post, gateway.uri.to_s)
    end
  end

  context 'remove_customer' do
    let(:customer) { Factory.build(:existing_customer) }
    subject { gateway.remove_customer(customer) }
    it_should_behave_like 'a customer request'

    it 'is successful' do
      subject.should be_success
    end

    it 'does not make a service request' do
      WebMock.should_not have_requested(:post, gateway.uri.to_s)
    end
  end

  context 'add_customer_credit_card' do
    cached_request_context 'with a successful result',
      :scope => 'nmi_customer_vault_add_customer_credit_card_success' do
      subject { gateway.add_customer_credit_card(customer, credit_card) }
      it_should_behave_like 'a credit card request'

      it 'is successful' do
        subject.should be_success
      end
    end

    cached_request_context 'with an unsuccessful result',
      :scope => 'nmi_customer_vault_add_customer_credit_card_failure' do
      let(:credit_card) { Factory.build(:credit_card, :card_number => nil) }
      subject { gateway.add_customer_credit_card(customer, credit_card) }

      it 'returns a CreditCard result' do
        subject.result.should be_kind_of VaultedBilling::CreditCard
      end

      it 'is unsuccessful' do
        subject.should_not be_success
      end
    end
  end

  context 'update_customer_credit_card' do
    let(:customer) { Factory.build(:existing_customer, :id => '1934241072') }
    let(:credit_card) { Factory.build(:existing_credit_card, :id => '1934241072') }

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
  end

  context 'remove_customer_credit_card' do
    let(:customer) { Factory.build(:existing_customer, :id => '1934241072') }
    let(:credit_card) { Factory.build(:existing_credit_card, :id => '1934241072') }

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
      let(:credit_card) { Factory.build(:existing_credit_card, :id => 'VERYBADIDENTIFIER!') }
      subject { gateway.remove_customer_credit_card(customer, credit_card) }
      it_should_behave_like 'a credit card request'

      it 'is unsuccessful' do
        should_not be_success
      end
    end
  end

  context 'authorize' do
    let(:customer) { Factory.build(:existing_customer, :id => '1695556243') }
    let(:credit_card) { Factory.build(:existing_credit_card, :id => '1695556243') }
    
    cached_request_context 'with a successful result',
      :scope => 'nmi_customer_vault_authorize_success' do
      subject { gateway.authorize(customer, credit_card, 1.00) }
      it_should_behave_like 'a transaction request'
      
      it 'is successful' do
        should be_success
      end

      it('has an false AVS response') { subject.result.avs_response.should be_false }
      it('has a false CVV response') { subject.result.cvv_response.should be_false }
      it('has an authcode') { subject.result.authcode.should be_present }
      it('has a message') { subject.result.message.should be_present }
      it('has a response code') { subject.result.code.should be_present }
    end

    cached_request_context 'with an DECLINE result',
      :scope => 'nmi_customer_vault_authorize_decline' do
      subject { gateway.authorize(customer, credit_card, 0.01) }
      it_should_behave_like 'a transaction request'

      it 'is unsuccessful' do
        should_not be_success
      end
    end
  end

  context 'capture' do
    cached_request_context 'with a successful result',
      :scope => 'nmi_customer_vault_capture_success' do
      before(:each) do
        customer = gateway.add_customer(Factory.build(:customer)).result
        credit_card = gateway.add_customer_credit_card(customer, Factory.build(:credit_card)).result
        auth_transaction = gateway.authorize(customer, credit_card, 10.00).result
        @response = gateway.capture(auth_transaction.id, 5.00)
      end
      subject { @response }
      it_should_behave_like 'a transaction request'

      it 'is successful' do
        should be_success
      end
    end

    cached_request_context 'with a DECLINE result',
      :scope => 'nmi_customer_vault_capture_failure' do
      before(:each) do
        customer = gateway.add_customer(Factory.build(:customer)).result
        credit_card = gateway.add_customer_credit_card(customer, Factory.build(:credit_card)).result
        auth_transaction = gateway.authorize(customer, credit_card, 10.00).result
        @response = gateway.capture(auth_transaction.id, 500.00)
      end
      subject { @response }
      it_should_behave_like 'a transaction request'

      it 'is unsuccessful' do
        should_not be_success
      end
    end
  end

  context 'refund' do
    cached_request_context 'with a successful result',
      :scope => 'nmi_customer_vault_refund_success' do
      before(:each) do
        pending 'Does not appear to allow me to immediately refund a capture'
        customer = gateway.add_customer(Factory.build(:customer)).result
        credit_card = gateway.add_customer_credit_card(customer, Factory.build(:credit_card)).result
        auth_transaction = gateway.authorize(customer, credit_card, 10.00).result
        capture_transaction = gateway.capture(auth_transaction.id, 5.00).result
        @response = gateway.refund(capture_transaction, 3.00)
      end
      subject { @response }
      it_should_behave_like 'a transaction request'

      it 'is successful' do
        should be_success
      end
    end

    cached_request_context 'with a DECLINE result',
      :scope => 'nmi_customer_vault_refund_failure' do
      before(:each) do
        customer = gateway.add_customer(Factory.build(:customer)).result
        credit_card = gateway.add_customer_credit_card(customer, Factory.build(:credit_card)).result
        auth_transaction = gateway.authorize(customer, credit_card, 10.00).result
        capture_transaction = gateway.capture(auth_transaction.id, 5.00).result
        @response = gateway.refund(capture_transaction, 30.00)
      end
      subject { @response }
      it_should_behave_like 'a transaction request'

      it 'is unsuccessful' do
        should_not be_success
      end
    end
  end

  context 'void' do
    cached_request_context 'with a successful result',
      :scope => 'nmi_customer_vault_void_success' do
      before(:each) do
        customer = gateway.add_customer(Factory.build(:customer)).result
        credit_card = gateway.add_customer_credit_card(customer, Factory.build(:credit_card)).result
        auth_transaction = gateway.authorize(customer, credit_card, 10.00).result
        @response = gateway.void(auth_transaction.id)
      end
      subject { @response }
      it_should_behave_like 'a transaction request'

      it 'is successful' do
        should be_success
      end
    end

    cached_request_context 'with a DECLINE result',
      :scope => 'nmi_customer_vault_void_failure', :record => :new do
      before(:each) do
        @response = gateway.void('INVALIDID')
      end
      subject { @response }

      it 'returns a Transaction' do
        subject.result.should be_kind_of VaultedBilling::Transaction
      end

      it 'returns a Trnsaction without an identifier' do
        subject.result.id.should be_blank
      end

      it 'is unsuccessful' do
        should_not be_success
      end
    end
  end
end
