require File.expand_path('../../spec_helper', __FILE__)

describe VaultedBilling::Gateways::AuthorizeNetCim do
  let(:gateway) { VaultedBilling.gateway(:authorize_net_cim).new }

  it 'uses the correct test uri' do
    gateway.use_test_uri = true
    gateway.uri.to_s.should == 'https://apitest.authorize.net/xml/v1/request.api'
  end

  it 'uses the correct live uri' do
    gateway.use_test_uri = false
    gateway.uri.to_s.should == 'https://api.authorize.net/xml/v1/request.api'
  end

  context 'add_customer' do
    context 'with a successful result' do
      use_vcr_cassette 'authorize_net_cim/add_customer/success'
      let(:customer) { Factory.build(:customer) }
      subject { gateway.add_customer(customer) }
      it_should_behave_like 'a customer request'

      it 'is successful' do
        should be_success
      end

      its(:response_message) { should == 'Successful.' }
      its(:error_code) { should be_nil }
    end

    context 'with an unsuccessful result' do
      use_vcr_cassette 'authorize_net_cim/add_customer/failure'
      let(:customer) { VaultedBilling::Customer.new }
      subject { gateway.add_customer(customer) }

      it 'returns a Customer' do
        subject.should be_kind_of VaultedBilling::Customer
      end

      it 'is unsuccessful' do
        should_not be_success
      end

      its(:response_message) { should == 'One or more fields in the profile must contain a value.' }
      its(:error_code) { should == 'E00041' }
    end

    request_exception_context do
      let(:customer) { VaultedBilling::Customer.new }
      subject { gateway.add_customer(customer) }
      it_should_behave_like 'a failed connection attempt'
    end
  end

  context 'update_customer' do
    let(:customer) { gateway.add_customer(Factory.build(:customer)) }

    context 'with a successful result' do
      use_vcr_cassette 'authorize_net_cim/update_customer/success'
      subject { customer.email = 'updated@example.com'; gateway.update_customer(customer) }

      it_should_behave_like 'a customer request'

      it 'returns the given customer' do
        should == customer
      end

      it 'is successful' do
        should be_success
      end

      its(:response_message) { should == 'Successful.' }
      its(:error_code) { should be_nil }
    end

    context 'with an unsuccessful result' do
      use_vcr_cassette 'authorize_net_cim/update_customer/failure'
      subject { customer.vault_id = '1234567890'; gateway.update_customer(customer) }

      it 'returns a Customer' do
        subject.should be_kind_of VaultedBilling::Customer
      end

      it 'is unsuccessful' do
        should_not be_success
      end

      its(:response_message) { should == %|The record cannot be found.| }
      its(:error_code) { should == 'E00040' }
    end

    request_exception_context do
      subject { customer.vault_id = '1234567890'; gateway.update_customer(customer) }
      it_should_behave_like 'a failed connection attempt'
    end
  end

  context 'remove_customer' do
    context 'with a successful result' do
      use_vcr_cassette 'authorize_net_cim/remove_customer/success'
      let(:customer) { gateway.add_customer(Factory.build(:customer)) }
      subject { gateway.remove_customer(customer) }

      it_should_behave_like 'a customer request'

      it 'returns the given customer' do
        subject.should == customer
      end

      it 'is successful' do
        should be_success
      end
    end

    context 'with an unsuccessful result' do
      use_vcr_cassette 'authorize_net_cim/remove_customer/failure'
      let(:customer) { gateway.add_customer(Factory.build(:customer)) }
      subject { customer.vault_id = '1234567890'; gateway.remove_customer(customer) }

      it_should_behave_like 'a customer request'

      it 'returns the given customer' do
        subject.should == customer
      end

      it 'is unsuccessful' do
        should_not be_success
      end
    end

    request_exception_context do
      let(:customer) { gateway.add_customer(Factory.build(:customer)) }
      subject { customer.vault_id = '1234567890'; gateway.remove_customer(customer) }
      it_should_behave_like 'a failed connection attempt'
    end
  end

  context 'add_customer_credit_card' do
    context 'with a successful result' do
      use_vcr_cassette 'authorize_net_cim/add_customer_credit_card/success'
      let(:customer) { gateway.add_customer(Factory.build(:customer)) }
      let(:credit_card) { Factory.build(:credit_card) }
      subject { gateway.add_customer_credit_card(customer, credit_card) }

      it_should_behave_like 'a credit card request'

      it 'is successful' do
        should be_success
      end
    end

    context 'with an unsuccessful result' do
      use_vcr_cassette 'authorize_net_cim/add_customer_credit_card/failure'
      let(:customer) { gateway.add_customer(Factory.build(:customer)) }
      let(:credit_card) { Factory.build(:credit_card, :card_number => nil) }
      subject { gateway.add_customer_credit_card(customer, credit_card) }

      it 'returns a credit card' do
        subject.should be_kind_of VaultedBilling::CreditCard
      end

      it 'is unsuccessful' do
        should_not be_success
      end
    end

    request_exception_context do
      let(:customer) { gateway.add_customer(Factory.build(:customer)) }
      let(:credit_card) { Factory.build(:credit_card, :card_number => nil) }
      subject { gateway.add_customer_credit_card(customer, credit_card) }
      it_should_behave_like 'a failed connection attempt'
    end
  end

  context 'update_customer_credit_card' do
    context 'with a successful result' do
      use_vcr_cassette 'authorize_net_cim/update_customer_credit_card/success'
      let(:customer) { gateway.add_customer(Factory.build(:customer)) }
      let(:credit_card) { gateway.add_customer_credit_card(customer, Factory.build(:credit_card)) }
      subject { credit_card.expires_on += 365; gateway.update_customer_credit_card(customer, credit_card) }

      it_should_behave_like 'a credit card request'

      it 'returns the given credit card' do
        subject.should == credit_card
      end

      it 'is successful' do
        should be_success
      end
    end

    context 'with an unsuccessful result' do
      use_vcr_cassette 'authorize_net_cim/update_customer_credit_card/failure'
      let(:customer) { gateway.add_customer(Factory.build(:customer)) }
      let(:credit_card) { gateway.add_customer_credit_card(customer, Factory.build(:credit_card)) }
      subject { credit_card.card_number = '123456'; gateway.update_customer_credit_card(customer, credit_card) }

      it_should_behave_like 'a credit card request'

      it 'returns the given credit card' do
        subject.should == credit_card
      end

      it 'is unsuccessful' do
        should_not be_success
      end
    end

    request_exception_context do
      let(:customer) { gateway.add_customer(Factory.build(:customer)) }
      let(:credit_card) { gateway.add_customer_credit_card(customer, Factory.build(:credit_card)) }
      subject { credit_card.card_number = '123456'; gateway.update_customer_credit_card(customer, credit_card) }
      it_should_behave_like 'a failed connection attempt'
    end
  end

  context 'remove_customer_credit_card' do
    context 'with a successful result' do
      use_vcr_cassette 'authorize_net_cim/remove_customer_credit_card/success'
      let(:customer) { gateway.add_customer(Factory.build(:customer)) }
      let(:credit_card) { gateway.add_customer_credit_card(customer, Factory.build(:credit_card)) }
      subject { gateway.remove_customer_credit_card(customer, credit_card) }

      it_should_behave_like 'a credit card request'

      it 'is successful' do
        should be_success
      end
    end

    context 'with an unsuccessful result' do
      use_vcr_cassette 'authorize_net_cim/remove_customer_credit_card/failure'
      let(:customer) { gateway.add_customer(Factory.build(:customer)) }
      let(:credit_card) { gateway.add_customer_credit_card(customer, Factory.build(:credit_card)) }
      subject do
        gateway.remove_customer_credit_card(customer, credit_card)
        gateway.remove_customer_credit_card(customer, credit_card)
      end

      it_should_behave_like 'a credit card request'

      it 'is unsuccessful' do
        should_not be_success
      end
    end

    request_exception_context do
      let(:customer) { gateway.add_customer(Factory.build(:customer)) }
      let(:credit_card) { gateway.add_customer_credit_card(customer, Factory.build(:credit_card)) }
      subject do
        gateway.remove_customer_credit_card(customer, credit_card)
        gateway.remove_customer_credit_card(customer, credit_card)
      end
      it_should_behave_like 'a failed connection attempt'
    end
  end

  context 'authorize' do
    context 'with a successful result' do
      use_vcr_cassette 'authorize_net_cim/authorize/success'
      let(:customer) { gateway.add_customer(Factory.build(:customer)) }
      let(:credit_card) { gateway.add_customer_credit_card(customer, Factory.build(:credit_card)) }
      subject { gateway.authorize(customer, credit_card, 10.00) }

      it_should_behave_like 'a transaction request'

      it { should be_success }
      its(:masked_card_number) { should be_present }
    end

    context 'with an unsuccessful result' do
      use_vcr_cassette 'authorize_net_cim/authorize/failure'
      let(:customer) { gateway.add_customer(Factory.build(:customer)) }
      let(:credit_card) { gateway.add_customer_credit_card(customer, Factory.build(:credit_card)) }
      subject { gateway.authorize(customer, credit_card, 0.00) }

      it 'returns a transaction' do
        subject.should be_kind_of VaultedBilling::Transaction
      end

      it { should_not be_success }
      its(:masked_card_number) { should be_blank }
      its(:message) { should =~ /invalid according to its datatype/ }
      its(:code) { should == 'E00003' }
    end

    request_exception_context do
      let(:customer) { gateway.add_customer(Factory.build(:customer)) }
      let(:credit_card) { gateway.add_customer_credit_card(customer, Factory.build(:credit_card)) }
      subject { gateway.authorize(customer, credit_card, 1.00) }
      it_should_behave_like 'a failed connection attempt'

      it 'reports a transaction exception' do
        subject.message.should == 'There was a problem communicating with the card processor.'
      end
    end
  end

  context 'purchase' do
    context 'with a successful result' do
      use_vcr_cassette 'authorize_net_cim/purchase/success'
      let(:customer) { gateway.add_customer(Factory.build(:customer)) }
      let(:credit_card) { gateway.add_customer_credit_card(customer, Factory.build(:credit_card)) }
      subject { gateway.purchase(customer, credit_card, 5.00) }

      it_should_behave_like 'a transaction request'

      it { should be_success }
      its(:masked_card_number) { should be_present }
    end

    context 'with an unsuccessful result' do
      use_vcr_cassette 'authorize_net_cim/purchase/failure'
      let(:customer) { gateway.add_customer(Factory.build(:customer)) }
      let(:credit_card) { gateway.add_customer_credit_card(customer, Factory.build(:credit_card)) }
      subject { gateway.purchase(customer, credit_card, 0.00) }

      it 'returns a transaction' do
        subject.should be_kind_of VaultedBilling::Transaction
      end

      it { should_not be_success }
      its(:masked_card_number) { should be_blank }
    end

    request_exception_context do
      let(:customer) { gateway.add_customer(Factory.build(:customer)) }
      let(:credit_card) { gateway.add_customer_credit_card(customer, Factory.build(:credit_card)) }
      subject { gateway.purchase(customer, credit_card, 1.00) }
      it_should_behave_like 'a failed connection attempt'

      it 'reports a transaction exception' do
        subject.message.should == 'There was a problem communicating with the card processor.'
      end
    end
  end

  context 'capture' do
    context 'with a successful result' do
      use_vcr_cassette 'authorize_net_cim/capture/success'
      let(:customer) { gateway.add_customer(Factory.build(:customer)) }
      let(:credit_card) { gateway.add_customer_credit_card(customer, Factory.build(:credit_card)) }
      subject do
        auth_transaction = gateway.authorize(customer, credit_card, 10.00)
        gateway.capture(auth_transaction.id, 10.00)
      end

      it_should_behave_like 'a transaction request'
      it { should be_success }
      its(:masked_card_number) { should be_present }
    end

    context 'with an unsuccessful result' do
      use_vcr_cassette 'authorize_net_cim/capture/failure'
      let(:customer) { gateway.add_customer(Factory.build(:customer)) }
      let(:credit_card) { gateway.add_customer_credit_card(customer, Factory.build(:credit_card)) }
      subject do
        auth_transaction = gateway.authorize(customer, credit_card, 10.00)
        gateway.capture(auth_transaction.id, 11.00)
      end

      it_should_behave_like 'a transaction request'
      it { should_not be_success }
      its(:masked_card_number) { should be_blank }
    end

    request_exception_context do
      let(:customer) { gateway.add_customer(Factory.build(:customer)) }
      let(:credit_card) { gateway.add_customer_credit_card(customer, Factory.build(:credit_card)) }
      subject do
        auth_transaction = gateway.authorize(customer, credit_card, 10.00)
        gateway.capture(auth_transaction.id, 11.00)
      end
      it_should_behave_like 'a failed connection attempt'

      it 'reports a transaction exception' do
        subject.message.should == 'There was a problem communicating with the card processor.'
      end
    end
  end

  context 'refund' do
    context 'with a successful result' do
      before(:each) { pending 'Refund requires a settled transaction to operate against.' }
      subject do
        customer = credit_card = purchase_transaction = nil

        use_cached_requests(:scope => 'authorize_net_cim/refund/success') do
          customer = gateway.add_customer(Factory.build(:customer))
          credit_card = gateway.add_customer_credit_card(customer, Factory.build(:credit_card))
          purchase_transaction = gateway.purchase(customer, credit_card, 10.00)
        end

        use_cached_requests(:scope => 'authorize_net_cim/refund/success_2') do
          gateway.refund(purchase_transaction.id, 3.00, :masked_card_number => purchase_transaction.masked_card_number)
        end
      end

      it_should_behave_like 'a transaction request'
      it { should be_success }
      its(:masked_card_number) { should be_present }
    end

    context 'with an unsuccessful result' do
      subject do
        customer = credit_card = purchase_transaction = nil

        use_cached_requests(:scope => 'authorize_net_cim/refund/failure') do
          customer = gateway.add_customer(Factory.build(:customer))
          credit_card = gateway.add_customer_credit_card(customer, Factory.build(:credit_card))
          purchase_transaction = gateway.purchase(customer, credit_card, 10.00)
        end

        use_cached_requests(:scope => 'authorize_net_cim/refund/failure_2') do
          gateway.refund(purchase_transaction.id, 12.00, :masked_card_number => purchase_transaction.masked_card_number)
        end
      end

      it_should_behave_like 'a transaction request'
      it { should_not be_success }
      its(:masked_card_number) { should be_present }
    end

    request_exception_context do
      let(:customer) { gateway.add_customer(Factory.build(:customer)) }
      let(:credit_card) { gateway.add_customer_credit_card(customer, Factory.build(:credit_card)) }
      subject do
        gateway.refund('123456', 10.00)
      end
      it_should_behave_like 'a failed connection attempt'

      it 'reports a transaction exception' do
        subject.message.should == 'There was a problem communicating with the card processor.'
      end
    end
  end

  context 'void' do
    context 'with a successful result' do
      use_vcr_cassette 'authorize_net_cim/void/success'
      let(:customer) { gateway.add_customer(Factory.build(:customer)) }
      let(:credit_card) { gateway.add_customer_credit_card(customer, Factory.build(:credit_card)) }
      subject do
        auth_transaction = gateway.authorize(customer, credit_card, 10.00)
        gateway.void(auth_transaction.id)
      end

      it_should_behave_like 'a transaction request'
      it { should be_success }
      its(:masked_card_number) { should be_present }
    end

    context 'with an unsuccessful result' do
      use_vcr_cassette 'authorize_net_cim/void/failure'
      before(:each) { pending 'Figure out how to force an failing VOID request.' }
      let(:customer) { gateway.add_customer(Factory.build(:customer)) }
      let(:credit_card) { gateway.add_customer_credit_card(customer, Factory.build(:credit_card)) }
      subject do
        purchase_transaction = gateway.purchase(customer, credit_card, 10.00)
        gateway.void(purchase_transaction.id)
      end

      it_should_behave_like 'a transaction request'
      it { should_not be_success }
      its(:masked_card_number) { should be_blank }
    end

    request_exception_context do
      let(:customer) { gateway.add_customer(Factory.build(:customer)) }
      let(:credit_card) { gateway.add_customer_credit_card(customer, Factory.build(:credit_card)) }
      subject do
        auth_transaction = gateway.authorize(customer, credit_card, 10.00)
        gateway.void(auth_transaction.id)
      end
      it_should_behave_like 'a failed connection attempt'

      it 'reports a transaction exception' do
        subject.message.should == 'There was a problem communicating with the card processor.'
      end
    end
  end

  context 'with raw_options' do
    context 'with a successful result' do
      use_vcr_cassette 'authorize_net_cim/authorize/success'
      let(:gateway) { VaultedBilling.gateway(:authorize_net_cim).new(:username => 'LOGIN', :password => 'PASSWORD', :raw_options => 'x_duplicate_window=3').tap { |g| g.use_test_uri = true } }
      let(:customer) { gateway.add_customer(Factory.build(:customer)) }
      let(:credit_card) { gateway.add_customer_credit_card(customer, Factory.build(:credit_card)) }

      it 'includes the options in the request' do
        customer
        credit_card
        
        http = stub("http")
        http.should_receive(:post).
          with(%r{<extraOptions>x_duplicate_window=3</extraOptions>}m).
          and_raise(TestException)
        gateway.should_receive(:http).
          and_return(http)
        expect { gateway.authorize(customer, credit_card, 10.00) }.
          to raise_error(TestException)
      end
    end
  end
end
