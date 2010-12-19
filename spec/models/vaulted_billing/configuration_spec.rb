require 'spec_helper'

describe VaultedBilling::Configuration do
  let(:config) { VaultedBilling::Configuration.new }

  context 'test_mode' do
    subject { config.test_mode }

    context 'by default' do
      it { should be_true }
    end

    it { config.test_mode = true; should be_true }
    it { config.test_mode = false; should be_false }
  end

  [ 'authorize_net_cim',
    'nmi_customer_vault',
    'bogus' ].each do |gateway|
    context gateway do
      context 'by default' do
        subject { config.send(gateway) }
        its(:username) { should be_nil }
        its(:password) { should be_nil }
        its(:test_mode) { should be_true }
      end

      context 'with options set' do
        let(:config) do
          VaultedBilling::Configuration.new(gateway => {
            :username => 'username',
            :password => 'password',
            :test_mode => false
          })
        end
        subject { config.send(gateway) }

        its(:username) { should == 'username' }
        its(:password) { should == 'password' }
        its(:test_mode) { should be_false }
      end
    end
  end
end
