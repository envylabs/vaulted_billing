require File.expand_path('../../spec_helper', __FILE__)

describe VaultedBilling::Gateways::NmiCustomerVault do
  let(:gateway) { VaultedBilling.gateway(:nmi_customer_vault).new }

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

    context 'with a successful result' do
      use_vcr_cassette 'nmi_customer_vault/add_customer_credit_card/success'

      subject { gateway.add_customer_credit_card(customer, credit_card) }
      it_should_behave_like 'a credit card request'

      it 'is successful' do
        subject.should be_success
      end

      its(:response_message) { should == 'Customer Added' }
      its(:error_code) { should be_nil }
    end

    context 'with an unsuccessful result' do
      use_vcr_cassette 'nmi_customer_vault/add_customer_credit_card/failure'
      let(:credit_card) { Factory.build(:credit_card, :card_number => nil) }
      subject { gateway.add_customer_credit_card(customer, credit_card) }

      it 'returns a CreditCard' do
        subject.should be_kind_of VaultedBilling::CreditCard
      end

      it 'is unsuccessful' do
        subject.should_not be_success
      end

      its(:response_message) { should =~ /Required Field cc_number is Missing or Empty REFID:.+/ }
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

    context 'with a successful result' do
      use_vcr_cassette 'nmi_customer_vault/update_customer_credit_card/success'
      subject { gateway.update_customer_credit_card(customer, credit_card) }
      it_should_behave_like 'a credit card request'

      it 'is successful' do
        should be_success
      end
    end

    context 'with an unsuccessful result' do
      use_vcr_cassette 'nmi_customer_vault/update_customer_credit_card/failure'
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

    context 'with a successful result' do
     use_vcr_cassette 'nmi_customer_vault/remove_customer_credit_card/success'
      subject { gateway.remove_customer_credit_card(customer, credit_card) }
      it_should_behave_like 'a credit card request'

      it 'is successful' do
        should be_success
      end
    end

    context 'with an unsuccessful result' do
     use_vcr_cassette 'nmi_customer_vault/remove_customer_credit_card/failure'
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

    context 'with a successful result' do
      use_vcr_cassette 'nmi_customer_vault/purchase/success'
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

    context 'with an DECLINE result' do
      use_vcr_cassette 'nmi_customer_vault/purchase/decline'
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

    context 'with a successful result' do
      use_vcr_cassette 'nmi_customer_vault/authorize/success'
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

    context 'with an DECLINE result' do
      use_vcr_cassette 'nmi_customer_vault/authorize/decline'
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

    context 'with a successful result' do
      use_vcr_cassette 'nmi_customer_vault/capture/success'
      let(:capture) { gateway.capture(authorization.id, 5.00) }
      subject { capture }
      it_should_behave_like 'a transaction request'

      it 'is successful' do
        should be_success
      end
    end

    context 'with a DECLINE result' do
      use_vcr_cassette 'nmi_customer_vault/capture/failure'
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

    context 'with a successful result' do
      use_vcr_cassette 'nmi_customer_vault/refund/success'
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

    context 'with a DECLINE result' do
      use_vcr_cassette 'nmi_customer_vault/refund/failure'
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

    context 'with a successful result' do
      use_vcr_cassette 'nmi_customer_vault/void/success'
      let(:void) { gateway.void(authorization.id) }
      subject { void }
      it_should_behave_like 'a transaction request'

      it 'is successful' do
        should be_success
      end
    end

    context 'with a DECLINE result' do
      use_vcr_cassette 'nmi_customer_vault/void/failure'
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

  context 'with raw_options' do
    context 'with a successful result' do
      use_vcr_cassette 'nmi_customer_vault/authorize/success'
      let(:gateway) { VaultedBilling.gateway(:nmi_customer_vault).new(:username => 'demo', :password => 'password', :raw_options => 'dup_seconds=1') }
      let(:customer) { gateway.add_customer(Factory.build(:customer)) }
      let(:credit_card) { gateway.add_customer_credit_card(customer, Factory.build(:credit_card)) }

      it 'includes the options in the request' do
        customer
        credit_card

        http = stub("http")
        http.should_receive(:post).
          with(%r{&dup_seconds=1}m).
          and_raise(TestException)
        gateway.should_receive(:http).
          and_return(http)
        expect { gateway.authorize(customer, credit_card, 10.00) }.
          to raise_error(TestException)
      end
    end
  end
end
