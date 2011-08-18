require 'spec_helper'

describe VaultedBilling::CreditCard do
  let(:credit_card) { Factory.build :credit_card }
  subject { credit_card }

  context '#country' do
    let(:credit_card) { Factory.build :credit_card, :country => 'US' }
    subject { credit_card.country }

    it { should eql 'US' }
    its(:to_iso_3166) { should == 840 }

    context 'with a bad country code' do
      let(:credit_card) { Factory.build :credit_card, :country => 'BADCOUNTRY' }

      it { should eql 'BADCOUNTRY' }
      its(:to_iso_3166) { should be_nil }
    end
  end

  context '#to_vaulted_billing' do
    subject { credit_card.to_vaulted_billing }

    it 'returns itself' do
      subject.object_id.should == credit_card.object_id
    end
  end
end
