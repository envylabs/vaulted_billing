require File.expand_path(File.join(File.dirname(__FILE__), '..', 'spec_helper'))

describe VaultedBilling::Gateways::AuthorizeNetCim do
  let(:gateway) { VaultedBilling.gateway(:authorize_net_cim).new(:username => 'LOGIN', :password => 'PASSWORD').tap { |g| g.use_test_uri = true } }

  it 'uses the correct test uri' do
    gateway.use_test_uri = true
    gateway.uri.to_s.should == 'https://apitest.authorize.net/xml/v1/request.api'
  end

  it 'uses the correct live uri' do
    gateway.use_test_uri = false
    gateway.uri.to_s.should == 'https://api.authorize.net/xml/v1/request.api'
  end

  context 'add_customer' do
    cached_request_context 'with a successful result',
      :scope => 'authorize_net_cim_add_customer_success' do
      let(:customer) { Factory.build(:customer) }
      subject { gateway.add_customer(customer) }
      it_should_behave_like 'a customer request'

      it 'is successful' do
        should be_success
      end
    end

    cached_request_context 'with an unsuccessful result',
      :scope => 'authorize_net_cim_add_customer_failure' do
      let(:customer) { VaultedBilling::Customer.new }
      subject { gateway.add_customer(customer) }
      
      it 'returns a Customer' do
        subject.should be_kind_of VaultedBilling::Customer
      end

      it 'is unsuccessful' do
        should_not be_success
      end
    end
  end

  context 'update_customer' do
    let(:customer) { gateway.add_customer(Factory.build(:customer)) }

    cached_request_context 'with a successful result',
      :scope => 'authorize_net_cim_update_customer_success' do
      subject { customer.email = 'updated@example.com'; gateway.update_customer(customer) }

      it_should_behave_like 'a customer request'

      it 'returns the given customer' do
        subject.should == customer
      end

      it 'is successful' do
        should be_success
      end
    end

    cached_request_context 'with an unsuccessful result',
      :scope => 'authorize_net_cim_update_customer_failure' do
      subject { customer.vault_id = '1234567890'; gateway.update_customer(customer) }
      
      it 'returns a Customer' do
        subject.should be_kind_of VaultedBilling::Customer
      end

      it 'is unsuccessful' do
        should_not be_success
      end
    end
  end

  context 'remove_customer' do
    cached_request_context 'with a successful result',
      :scope => 'authorize_net_cim_remove_customer_success' do
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

    cached_request_context 'with an unsuccessful result',
      :scope => 'authorize_net_cim_remove_customer_failure' do
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
  end

  context 'add_customer_credit_card' do
    cached_request_context 'with a successful result',
      :scope => 'authorize_net_cim_add_customer_credit_card_success' do
      let(:customer) { gateway.add_customer(Factory.build(:customer)) }
      let(:credit_card) { Factory.build(:credit_card) }
      subject { gateway.add_customer_credit_card(customer, credit_card) }

      it_should_behave_like 'a credit card request'

      it 'is successful' do
        should be_success
      end
    end

    cached_request_context 'with an unsuccessful result',
      :scope => 'authorize_net_cim_add_customer_credit_card_failure' do
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
  end

  context 'update_customer_credit_card' do
    cached_request_context 'with a successful result',
      :scope => 'authorize_net_cim_update_customer_credit_card_success' do
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

    cached_request_context 'with an unsuccessful result',
      :scope => 'authorize_net_cim_update_customer_credit_card_failure' do
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
  end

  context 'remove_customer_credit_card' do
    cached_request_context 'with a successful result',
      :scope => 'authorize_net_cim_remove_customer_credit_card_success' do
      let(:customer) { gateway.add_customer(Factory.build(:customer)) }
      let(:credit_card) { gateway.add_customer_credit_card(customer, Factory.build(:credit_card)) }
      subject { gateway.remove_customer_credit_card(customer, credit_card) }

      it_should_behave_like 'a credit card request'

      it 'is successful' do
        should be_success
      end
    end

    cached_request_context 'with an unsuccessful result',
      :scope => 'authorize_net_cim_remove_customer_credit_card_failure' do
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
  end

  context 'authorize' do
    cached_request_context 'with a successful result',
      :scope => 'authorize_net_cim_authorize_success' do
      let(:customer) { gateway.add_customer(Factory.build(:customer)) }
      let(:credit_card) { gateway.add_customer_credit_card(customer, Factory.build(:credit_card)) }
      subject { gateway.authorize(customer, credit_card, 10.00) }

      it_should_behave_like 'a transaction request'

      it 'is successful' do
        should be_success
      end
    end

    cached_request_context 'with an unsuccessful result',
      :scope => 'authorize_net_cim_authorize_failure' do
      let(:customer) { gateway.add_customer(Factory.build(:customer)) }
      let(:credit_card) { gateway.add_customer_credit_card(customer, Factory.build(:credit_card)) }
      subject { gateway.authorize(customer, credit_card, 0.00) }

      it 'returns a transaction' do
        subject.should be_kind_of VaultedBilling::Transaction
      end

      it 'is unsuccessful' do
        should_not be_success
      end
    end

    context 'with a connection exception' do
      let(:customer) { gateway.add_customer(Factory.build(:customer)) }
      let(:credit_card) { gateway.add_customer_credit_card(customer, Factory.build(:credit_card)) }

      before(:each) do
        WebMock.stub_request(:post, %r{^https://.*?\.authorize\.net/}).
          to_raise(Errno::ECONNRESET)
      end

      subject { gateway.authorize(customer, credit_card, 1.00) }

      it 'is unsuccessful' do
        should_not be_success
      end

      it 'reports an exception' do
        subject.message.should == 'There was a problem communicating with the card processor.'
      end
    end
  end

  context 'capture' do
    cached_request_context 'with a successful result',
      :scope => 'authorize_net_cim_capture_success' do
      let(:customer) { gateway.add_customer(Factory.build(:customer)) }
      let(:credit_card) { gateway.add_customer_credit_card(customer, Factory.build(:credit_card)) }
      subject do
        auth_transaction = gateway.authorize(customer, credit_card, 10.00)
        gateway.capture(auth_transaction.id, 10.00)
      end

      it_should_behave_like 'a transaction request'

      it 'is successful' do
        should be_success
      end
    end

    cached_request_context 'with an unsuccessful result',
      :scope => 'authorize_net_cim_capture_failure' do
      let(:customer) { gateway.add_customer(Factory.build(:customer)) }
      let(:credit_card) { gateway.add_customer_credit_card(customer, Factory.build(:credit_card)) }
      subject do
        auth_transaction = gateway.authorize(customer, credit_card, 10.00)
        gateway.capture(auth_transaction.id, 11.00)
      end

      it_should_behave_like 'a transaction request'

      it 'is unsuccessful' do
        should_not be_success
      end
    end

    context 'with a connection exception' do
      before(:each) do
        WebMock.stub_request(:post, %r{^https://.*?\.authorize\.net/}).
          to_raise(Errno::ECONNRESET)
      end

      subject { gateway.capture('IDENTIFIER', 1.00) }

      it 'is unsuccessful' do
        should_not be_success
      end

      it 'reports an exception' do
        subject.message.should == 'There was a problem communicating with the card processor.'
      end
    end
  end

  context 'refund' do
    before(:each) { pending 'Need a settled transaction to test against' }
    cached_request_context 'with a successful result',
      :scope => 'authorize_net_cim_refund_success' do
      let(:customer) { gateway.add_customer(Factory.build(:customer)) }
      let(:credit_card) { gateway.add_customer_credit_card(customer, Factory.build(:credit_card)) }
      subject do
        auth_transaction = gateway.authorize(customer, credit_card, 10.00)
        capture_transaction = gateway.capture(auth_transaction.id, 10.00)
        gateway.refund(capture_transaction.id, 3.00)
      end

      it_should_behave_like 'a transaction request'

      it 'is successful' do
        should be_success
      end
    end
  end

  context 'void' do
    cached_request_context 'with a successful result',
      :scope => 'authorize_net_cim_void_success' do
      let(:customer) { gateway.add_customer(Factory.build(:customer)) }
      let(:credit_card) { gateway.add_customer_credit_card(customer, Factory.build(:credit_card)) }
      subject do
        auth_transaction = gateway.authorize(customer, credit_card, 10.00)
        gateway.void(auth_transaction.id)
      end

      it_should_behave_like 'a transaction request'

      it 'is successful' do
        should be_success
      end
    end
    
    cached_request_context 'with an unsuccessful result',
      :scope => 'authorize_net_cim_void_failure' do
      before(:each) { pending 'Need a settled transaction to test against' }
      let(:customer) { gateway.add_customer(Factory.build(:customer)) }
      let(:credit_card) { gateway.add_customer_credit_card(customer, Factory.build(:credit_card)) }
      subject do
        auth_transaction = gateway.authorize(customer, credit_card, 10.00)
        capture_transaction = gateway.capture(auth_transaction.id, 10.00)
        gateway.void(auth_transaction.id)
      end

      it_should_behave_like 'a transaction request'

      it 'is unsuccessful' do
        should_not be_success
      end
    end
  end

end
