module RSpecHelpers
  module InstanceMethods
    def freeze_time(time=nil)
      (time ||= Time.now).tap { |now| Time.stub(:now).and_return(now) }
    end

    shared_examples_for "a transaction request" do
      it 'returns a Transaction' do
        subject.should be_kind_of(VaultedBilling::Transaction)
      end

      it 'returns a Transaction with an identifier' do
        subject.id.should_not be_blank
      end
    end

    shared_examples_for 'a customer request' do
      it 'returns a Customer' do
        subject.should be_kind_of(VaultedBilling::Customer)
      end

      it 'returns a Customer with an identifier' do
        subject.id.should_not be_blank
      end
    end

    shared_examples_for 'a credit card request' do
      it 'returns a CreditCard' do
        subject.should be_kind_of(VaultedBilling::CreditCard)
      end

      it 'returns a CreditCard with an identifier' do
        subject.id.should_not be_blank
      end
    end
  end
end

RSpec.configure do |config|
  config.include RSpecHelpers::InstanceMethods
end
