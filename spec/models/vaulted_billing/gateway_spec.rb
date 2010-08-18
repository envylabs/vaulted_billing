require 'spec_helper'

class TestGateway
  include VaultedBilling::Gateway
end

describe VaultedBilling::Gateway do
  let(:gateway) { TestGateway.new }
  let(:customer) { Factory.build(:customer) }
  let(:credit_card) { Factory.build(:credit_card) }

  subject { gateway }

  context 'add_customer' do
    it 'raises NotImplementedError' do
      expect { gateway.add_customer(customer) }.to raise_error(NotImplementedError)
    end
  end

  context 'update_customer' do
    it 'raises NotImplementedError' do
      expect { gateway.update_customer(customer) }.to raise_error(NotImplementedError)
    end
  end

  context 'remove_customer' do
    it 'raises NotImplementedError' do
      expect { gateway.remove_customer(customer) }.to raise_error(NotImplementedError)
    end
  end

  context 'add_customer_credit_card' do
    it 'raises NotImplementedError' do
      expect { gateway.add_customer_credit_card(customer, credit_card) }.to raise_error(NotImplementedError)
    end
  end

  context 'update_customer_credit_card' do
    it 'raises NotImplementedError' do
      expect { gateway.update_customer_credit_card(customer, credit_card) }.to raise_error(NotImplementedError)
    end
  end

  context 'remove_customer_credit_card' do
    it 'raises NotImplementedError' do
      expect { gateway.remove_customer_credit_card(customer, credit_card) }.to raise_error(NotImplementedError)
    end
  end

  context 'authorize' do
    it 'raises NotImplementedError' do
      expect { gateway.authorize(customer, credit_card, 1) }.to raise_error(NotImplementedError)
    end
  end

  context 'capture' do
    it 'raises NotImplementedError' do
      expect { gateway.capture('transactionid', 1) }.to raise_error(NotImplementedError)
    end
  end

  context 'refund' do
    it 'raises NotImplementedError' do
      expect { gateway.refund('transactionid', 1) }.to raise_error(NotImplementedError)
    end
  end

  context 'void' do
    it 'raises NotImplementedError' do
      expect { gateway.void('transactionid') }.to raise_error(NotImplementedError)
    end
  end
end
