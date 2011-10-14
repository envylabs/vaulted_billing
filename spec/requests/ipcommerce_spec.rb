require 'spec_helper'
require 'ostruct'

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
    let(:authorization) { gateway.authorize(customer, credit_card, 11.00, { :merchant_profile_id => merchant_profile_id }) }
    subject { authorization }

    context 'with a new credit card' do
      context 'when successful' do
        
        context 'for a general success' do
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
        
        context 'with AVS Responses' do
          context 'with match' do
            use_vcr_cassette 'ipcommerce/authorize/new/avs/match'
            let(:credit_card) { Factory.build(:ipcommerce_credit_card, :street_address => '1000 1st Av', :postal_code => '10101') }
            it_should_behave_like 'a transaction request'
            it { should be_success }

            context 'the avs response' do
              subject { OpenStruct.new(authorization.avs_response) }
              its(:result) { should == 'Y' }
              its(:address) { should == 'Match' }
              its(:postal_code) { should == 'Match' }
            end
          end

          context 'with no match' do
            use_vcr_cassette 'ipcommerce/authorize/new/avs/no_match'
            let(:credit_card) { Factory.build(:ipcommerce_credit_card) }
            it_should_behave_like 'a transaction request'
            it { should be_success }

            context 'the avs response' do
              subject { OpenStruct.new(authorization.avs_response) }
              its(:result) { should == 'N' }
              its(:address) { should == 'No Match' }
              its(:postal_code) { should == 'No Match' }
            end
          end

          context 'without AVS sent' do
            use_vcr_cassette 'ipcommerce/authorize/new/avs/not_sent'
            let(:credit_card) { Factory.build(:blank_credit_card, :card_number => '5454545454545454',
                                                                  :expires_on => Date.new(2010, 12, 31)) }
            it_should_behave_like 'a transaction request'
            it { should be_success }
            its(:avs_response) { should be_nil }
          end

          context 'with not included' do
            use_vcr_cassette 'ipcommerce/authorize/new/avs/not_included'
            let(:credit_card) { Factory.build(:ipcommerce_credit_card, :street_address => nil) }
            it_should_behave_like 'a transaction request'
            it { should be_success }

            context 'the avs response' do
              subject { OpenStruct.new(authorization.avs_response) }
              its(:result) { should == 'N' }
              its(:address) { should == 'Not Included' }
              its(:postal_code) { should == 'No Match' }
            end
          end

          context 'with issuer not certified' do
            use_vcr_cassette 'ipcommerce/authorize/new/avs/issuer_not_certified'
            let(:credit_card) { Factory.build(:ipcommerce_credit_card, :street_address => "2000 2nd Av", :postal_code => '20202') }
            it_should_behave_like 'a transaction request'
            it { should be_success }

            context 'the avs response' do
              subject { OpenStruct.new(authorization.avs_response) }
              its(:result) { should == 'E' }
              its(:address) { should == 'Issuer Not Certified' }
              its(:postal_code) { should == 'Issuer Not Certified' }
            end
          end

          context 'with no response from card association' do
            use_vcr_cassette 'ipcommerce/authorize/new/avs/no_response_from_card_association'
            let(:credit_card) { Factory.build(:ipcommerce_credit_card, :street_address => "3000 3rd Av", :postal_code => '30303') }
            it_should_behave_like 'a transaction request'
            it { should be_success }

            context 'the avs response' do
              subject { OpenStruct.new(authorization.avs_response) }
              its(:result) { should == 'R' }
              its(:address) { should == 'No Response From Card Association' }
              its(:postal_code) { should == 'No Response From Card Association' }
            end
          end

          context 'with not verified' do
            use_vcr_cassette 'ipcommerce/authorize/new/avs/not_verified'
            let(:credit_card) { Factory.build(:ipcommerce_credit_card, :street_address => "4000 4th Av", :postal_code => '40404') }
            it_should_behave_like 'a transaction request'
            it { should be_success }

            context 'the avs response' do
              subject { OpenStruct.new(authorization.avs_response) }
              its(:result) { should == 'S' }
              its(:address) { should == 'Not Verified' }
              its(:postal_code) { should == 'Not Verified' }
            end
          end

          context 'with bad format' do
            use_vcr_cassette 'ipcommerce/authorize/new/avs/bad_format'
            let(:credit_card) { Factory.build(:ipcommerce_credit_card, :street_address => "5000 5th Av", :postal_code => '50505') }
            it_should_behave_like 'a transaction request'
            it { should be_success }

            context 'the avs response' do
              subject { OpenStruct.new(authorization.avs_response) }
              its(:result) { should == 'F' }
              its(:address) { should == 'Bad Format' }
              its(:postal_code) { should == 'Bad Format' }
            end
          end
        end

        # The various reasons that a card can be declined. We need to return them all.
        context 'with CVV Responses' do
          context 'with no match' do
            use_vcr_cassette 'ipcommerce/authorize/new/cvv/no_match'
            let(:credit_card) { Factory.build(:ipcommerce_credit_card, :cvv_number => '222') }
            it_should_behave_like 'a transaction request'
            it { should be_success }
            its(:cvv_response) { should == "No Match" }
          end

          context 'with not processed' do
            use_vcr_cassette 'ipcommerce/authorize/new/cvv/not_processed'
            let(:credit_card) { Factory.build(:ipcommerce_credit_card, :cvv_number => '333') }
            it_should_behave_like 'a transaction request'
            it { should be_success }
            its(:cvv_response) { should == "Not Processed" }
          end

          context 'with merchant ind no code present' do
            use_vcr_cassette 'ipcommerce/authorize/new/cvv/no_code_present'
            let(:credit_card) { Factory.build(:ipcommerce_credit_card, :cvv_number => '444') }
            it_should_behave_like 'a transaction request'
            it { should be_success }
            its(:cvv_response) { should == "No Code Present" }
          end

          context 'with should have been present' do
            use_vcr_cassette 'ipcommerce/authorize/new/cvv/should_have_been_present'
            let(:credit_card) { Factory.build(:ipcommerce_credit_card, :cvv_number => '555') }
            it_should_behave_like 'a transaction request'
            it { should be_success }
            its(:cvv_response) { should == "Should Have Been Present" }
          end

          context 'with issuer not certified' do
            use_vcr_cassette 'ipcommerce/authorize/new/cvv/issuer_not_certified'
            let(:credit_card) { Factory.build(:ipcommerce_credit_card, :cvv_number => '666') }
            it_should_behave_like 'a transaction request'
            it { should be_success }
            its(:cvv_response) { should == "Issuer Not Certified" }
          end

          context 'with invalid' do
            use_vcr_cassette 'ipcommerce/authorize/new/cvv/invalid'
            let(:credit_card) { Factory.build(:ipcommerce_credit_card, :cvv_number => '777') }
            it_should_behave_like 'a transaction request'
            it { should be_success }
            its(:cvv_response) { should == "Invalid" }
          end

          context 'with no response from card association' do
            use_vcr_cassette 'ipcommerce/authorize/new/cvv/no_response'
            let(:credit_card) { Factory.build(:ipcommerce_credit_card, :cvv_number => '888') }
            it_should_behave_like 'a transaction request'
            it { should be_success }
            its(:cvv_response) { should == "No Response" }
          end

          context 'with not applicable' do
            use_vcr_cassette 'ipcommerce/authorize/new/cvv/not_applicable'
            let(:credit_card) { Factory.build(:ipcommerce_credit_card, :cvv_number => '999') }
            it_should_behave_like 'a transaction request'
            it { should be_success }
            its(:cvv_response) { should == "Not Applicable" }
          end
        end
      end

      context 'with a failure' do
        context 'due to an invalid card number' do
          let(:credit_card) { Factory.build(:invalid_credit_card) }
          use_vcr_cassette 'ipcommerce/authorize/new/failure'

          it_should_behave_like 'a transaction request'
          it { should_not be_success }
          its(:message) { should_not == "APPROVED" }
        end
      end
    end

    context 'with a credit card on file' do
      let(:credit_card) { gateway.add_customer_credit_card customer, Factory.build(:ipcommerce_credit_card) }

      context 'when successful' do
        use_vcr_cassette 'ipcommerce/authorize/existing/success'
        let(:credit_card) { gateway.add_customer_credit_card(customer, Factory.build(:ipcommerce_credit_card, :street_address => '1000 1st Av', :postal_code => '10101'), { :merchant_profile_id => merchant_profile_id }) }

        it_should_behave_like 'a transaction request'
        it { should be_success }
        its(:id) { should_not be_nil }
        its(:masked_card_number) { should be_present }
        its(:authcode) { should_not be_nil }
        its(:message) { should == "APPROVED" }
        its(:code) { should == 1 }
        
        context 'the avs response' do
          subject { OpenStruct.new(authorization.avs_response) }
          its(:result) { should == 'Y' }
          its(:address) { should == 'Match' }
          its(:postal_code) { should == 'Match' }
        end
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
