require 'spec_helper'

describe VaultedBilling::CreditCard do
  let(:credit_card) { Factory.build :credit_card }
  subject { credit_card }

  context '#country' do
    let(:credit_card) { Factory.build :credit_card, :country => 'US' }
    subject { credit_card.country }

    it { should eql 'US' }
    its(:to_iso_3166) { should == 840 }
    its(:to_ipcommerce_id) { should ==  234 }

    context 'with a bad country code' do
      let(:credit_card) { Factory.build :credit_card, :country => 'BADCOUNTRY' }

      it { should eql 'BADCOUNTRY' }
      its(:to_iso_3166) { should be_nil }
      its(:to_ipcommerce_id) { should == 0 }
    end
    
    context "in Australia" do
      let(:credit_card) { Factory.build :credit_card, :country => 'AU' }
      its(:to_ipcommerce_id) { should == 14 }
    end

    context "in Canada" do
      let(:credit_card) { Factory.build :credit_card, :country => 'CA' }
      its(:to_ipcommerce_id) { should == 39 }
    end
    
    context "in France" do
      let(:credit_card) { Factory.build :credit_card, :country => 'FR' }
      its(:to_ipcommerce_id) { should == 74 }
    end
    
    context "in Mexico" do
      let(:credit_card) { Factory.build :credit_card, :country => 'MX' }
      its(:to_ipcommerce_id) { should == 143 }
    end

    context "in New Zealand" do
      let(:credit_card) { Factory.build :credit_card, :country => 'NZ' }
      its(:to_ipcommerce_id) { should == 159 }
    end

    context "in United Kingdom" do
      let(:credit_card) { Factory.build :credit_card, :country => 'GB' }
      its(:to_ipcommerce_id) { should == 233 }
    end
  end

  context '#to_vaulted_billing' do
    subject { credit_card.to_vaulted_billing }

    it 'returns itself' do
      subject.object_id.should == credit_card.object_id
    end
  end
end
