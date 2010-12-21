require File.expand_path('../../spec_helper', __FILE__)

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

      its(:response_message) { should == 'Successful.' }
      its(:error_code) { should be_nil }
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

      its(:response_message) { should == 'One or more fields in profile must contain a value.' }
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

    cached_request_context 'with a successful result',
      :scope => 'authorize_net_cim_update_customer_success' do
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

    cached_request_context 'with an unsuccessful result',
      :scope => 'authorize_net_cim_update_customer_failure' do
      subject { customer.vault_id = '1234567890'; gateway.update_customer(customer) }

      it 'returns a Customer' do
        subject.should be_kind_of VaultedBilling::Customer
      end

      it 'is unsuccessful' do
        should_not be_success
      end

      its(:response_message) { should == %|The element 'profile' in namespace 'AnetApi/xml/v1/schema/AnetApiSchema.xsd' has invalid child element 'merchantCustomerId' in namespace 'AnetApi/xml/v1/schema/AnetApiSchema.xsd'.| }
      its(:error_code) { should == 'E00003' }
    end

    request_exception_context do
      subject { customer.vault_id = '1234567890'; gateway.update_customer(customer) }
      it_should_behave_like 'a failed connection attempt'
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

    request_exception_context do
      let(:customer) { gateway.add_customer(Factory.build(:customer)) }
      subject { customer.vault_id = '1234567890'; gateway.remove_customer(customer) }
      it_should_behave_like 'a failed connection attempt'
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

    request_exception_context do
      let(:customer) { gateway.add_customer(Factory.build(:customer)) }
      let(:credit_card) { Factory.build(:credit_card, :card_number => nil) }
      subject { gateway.add_customer_credit_card(customer, credit_card) }
      it_should_behave_like 'a failed connection attempt'
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

    request_exception_context do
      let(:customer) { gateway.add_customer(Factory.build(:customer)) }
      let(:credit_card) { gateway.add_customer_credit_card(customer, Factory.build(:credit_card)) }
      subject { credit_card.card_number = '123456'; gateway.update_customer_credit_card(customer, credit_card) }
      it_should_behave_like 'a failed connection attempt'
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
    cached_request_context 'with a successful result',
      :scope => 'authorize_net_cim_authorize_success' do
      let(:customer) { gateway.add_customer(Factory.build(:customer)) }
      let(:credit_card) { gateway.add_customer_credit_card(customer, Factory.build(:credit_card)) }
      subject { gateway.authorize(customer, credit_card, 10.00) }

      it_should_behave_like 'a transaction request'

      it { should be_success }
      its(:masked_card_number) { should be_present }
    end

    cached_request_context 'with an unsuccessful result',
      :scope => 'authorize_net_cim_authorize_failure' do
      let(:customer) { gateway.add_customer(Factory.build(:customer)) }
      let(:credit_card) { gateway.add_customer_credit_card(customer, Factory.build(:credit_card)) }
      subject { gateway.authorize(customer, credit_card, 0.00) }

      it 'returns a transaction' do
        subject.should be_kind_of VaultedBilling::Transaction
      end

      it { should_not be_success }
      its(:masked_card_number) { should be_blank }
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
    cached_request_context 'with a successful result',
      :scope => 'authorize_net_cim_purchase_success' do
      let(:customer) { gateway.add_customer(Factory.build(:customer)) }
      let(:credit_card) { gateway.add_customer_credit_card(customer, Factory.build(:credit_card)) }
      subject { gateway.purchase(customer, credit_card, 5.00) }

      it_should_behave_like 'a transaction request'

      it { should be_success }
      its(:masked_card_number) { should be_present }
    end

    cached_request_context 'with an unsuccessful result',
      :scope => 'authorize_net_cim_purchase_failure' do
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
    cached_request_context 'with a successful result',
      :scope => 'authorize_net_cim_capture_success' do
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

    cached_request_context 'with an unsuccessful result',
      :scope => 'authorize_net_cim_capture_failure' do
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
      subject do
        customer = credit_card = purchase_transaction = nil

        use_cached_requests(:scope => 'authorize_net_cim_refund_success') do
          customer = gateway.add_customer(Factory.build(:customer))
          credit_card = gateway.add_customer_credit_card(customer, Factory.build(:credit_card))
          purchase_transaction = gateway.purchase(customer, credit_card, 10.00)
        end

        use_cached_requests(:scope => 'authorize_net_cim_refund_success_2') do
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

        use_cached_requests(:scope => 'authorize_net_cim_refund_failure', :record => :new_episodes) do
          customer = gateway.add_customer(Factory.build(:customer))
          credit_card = gateway.add_customer_credit_card(customer, Factory.build(:credit_card))
          purchase_transaction = gateway.purchase(customer, credit_card, 10.00)
        end

        use_cached_requests(:scope => 'authorize_net_cim_refund_failure_2', :record => :new_episodes) do
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
    cached_request_context 'with a successful result',
      :scope => 'authorize_net_cim_void_success' do
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

    cached_request_context 'with an unsuccessful result',
      :scope => 'authorize_net_cim_void_failure' do
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

end
