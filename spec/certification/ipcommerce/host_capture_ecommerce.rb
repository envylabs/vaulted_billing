require 'spec_helper'
require_relative 'ipcommerce_transaction.rb'

describe VaultedBilling::Gateways::Ipcommerce do
  let(:gateway) { VaultedBilling.gateway(:ipcommerce).new }
  let(:options) { { :merchant_profile_id => 'TicketTest_E4FB800001', :workflow_id => 'E4FB800001' } } # Host Capture: FDC

  before(:all) do
    puts "test code, status code, approval code, status message, transaction id"
  end

  context "AuthorizeAndCapture" do
    let(:purchase) { gateway.purchase(nil, credit_card, amount, options) }
    
    subject { IpcommerceTransaction.new(code, purchase) }
    
    context 'F_A1' do
      let(:code) { "F_A1" }
      let(:amount) { 12.00 }
      let(:credit_card) { Factory.build(:blank_credit_card, :card_number => '4111111111111111', :postal_code => '10101') }
      use_vcr_cassette 'ipcommerce/certification/host/f_a1'
      
      it "outputs the result" do
        puts subject.print
      end
    end
    
    context 'F_A2' do
      let(:code) { "F_A2" }
      let(:amount) { 12.00 }
      let(:credit_card) { Factory.build(:blank_credit_card, :card_number => '6011000995504101') }
      use_vcr_cassette 'ipcommerce/certification/host/f_a2'
      
      it "outputs the result" do
        puts subject.print
      end
    end
    
    context 'F_A3' do
      let(:code) { "F_A3" }
      let(:amount) { 25.00 }
      let(:credit_card) { Factory.build(:blank_credit_card, :card_number => '371449635398456', :cvv_number => '1111') }
      use_vcr_cassette 'ipcommerce/certification/host/f_a3'
      
      it "outputs the result" do
        puts subject.print
      end
    end
    
    context 'F_A4' do
      let(:code) { "F_A4" }
      let(:amount) { 26.00 }
      let(:credit_card) { Factory.build(:blank_credit_card, :card_number => '5454545454545454', :cvv_number => '111', :postal_code => '10101') }
      use_vcr_cassette 'ipcommerce/certification/host/f_a4'
      
      it "outputs the result" do
        puts subject.print
      end
    end
    
    context 'F_A5' do
      let(:code) { "F_A5" }
      let(:amount) { 12.00 }
      let(:credit_card) { Factory.build(:blank_credit_card, :card_number => '371449635398456', :postal_code => '10101') }
      use_vcr_cassette 'ipcommerce/certification/host/f_a5'
      
      it "outputs the result" do
        puts subject.print
      end
    end
    
    context 'F_A6' do
      let(:code) { "F_A6" }
      let(:amount) { 10.83 }
      let(:credit_card) { Factory.build(:blank_credit_card, :card_number => '4111111111111111', :cvv_number => '777') }
      use_vcr_cassette 'ipcommerce/certification/host/f_a6'
      
      it "outputs the result" do
        puts subject.print
      end
    end
  end
  
  
  context 'ReturnById' do
    let(:purchase) { gateway.purchase(nil, credit_card, purchase_amount, options) }
    let(:refund) { gateway.refund(purchase.id, refund_amount, options) }
    
    context 'F_B1 - F_B2' do
      let(:purchase_amount) { 29.00 }
      let(:refund_amount) { 12.00 }
      let(:credit_card) { Factory.build(:blank_credit_card, :card_number => '4111111111111111', :cvv_number => '111', :postal_code => '10101') }
      use_vcr_cassette 'ipcommerce/certification/host/f_b1-b2'
      
      it "ouputs the result" do
        puts IpcommerceTransaction.new('F_B1', purchase).print
        puts IpcommerceTransaction.new('F_B2', refund).print
      end
    end
    
    context 'F_B3 - F_B4' do
      let(:purchase_amount) { 7.00 }
      let(:refund_amount) { purchase_amount }
      let(:credit_card) { Factory.build(:blank_credit_card, :card_number => '5454545454545454', :cvv_number => '111', :postal_code => '10101') }
      use_vcr_cassette 'ipcommerce/certification/host/f_b3-b4'
      
      it "ouputs the result" do
        puts IpcommerceTransaction.new('F_B3', purchase).print
        puts IpcommerceTransaction.new('F_B4', refund).print
      end
    end  
  end

  context 'Undo (Void)' do
    let(:authorization) { gateway.authorize(nil, credit_card, amount, options) }
    let(:void) { gateway.void(authorization.id, options) }

    context 'F_C1 - F_C2' do
      let(:amount) { 57.00 }
      let(:credit_card) { Factory.build(:blank_credit_card, :card_number => '5454545454545454', :cvv_number => '111') }
      use_vcr_cassette 'ipcommerce/certification/host/f_c1-c2'

      it "ouputs the result" do
        puts IpcommerceTransaction.new("F_C1", authorization).print
        puts IpcommerceTransaction.new("F_C2", void).print
      end
    end

    context 'F_C3 - F_C4' do
      let(:amount) { 55.00 }
      let(:authorization) { gateway.authorize(nil, credit_card, amount, options) }
      let(:credit_card) { Factory.build(:blank_credit_card, :card_number => '4111111111111111', :postal_code => '10101') }
      use_vcr_cassette 'ipcommerce/certification/host/f_c3-c4'

      it "ouputs the result" do
        puts IpcommerceTransaction.new("F_C3", authorization).print
        puts IpcommerceTransaction.new("F_C4", void).print
      end
    end
  end
  
  
  context 'Non-Standard Card Tests (Purchase)' do
    let(:purchase) { gateway.purchase(nil, credit_card, amount, options) }

    context 'F_D1' do
      let(:amount) { 17.00 }
      let(:credit_card) { Factory.build(:blank_credit_card, :card_number => '6011000995504101', :cvv_number => '111', :postal_code => '10101') }
      use_vcr_cassette 'ipcommerce/certification/host/f_d1'

      it "ouputs the result" do
        puts IpcommerceTransaction.new("F_D1", purchase).print
      end
    end

    context 'F_D2' do
      let(:amount) { 33.03 }
      let(:credit_card) { Factory.build(:blank_credit_card, :card_number => '4111111111111111', :postal_code => '10101') }
      use_vcr_cassette 'ipcommerce/certification/host/f_d2'

      it "ouputs the result" do
        puts IpcommerceTransaction.new("F_D2", purchase).print
      end
    end
    
    context 'F_D3' do
      let(:amount) { 34.02 }
      let(:credit_card) { Factory.build(:blank_credit_card, :card_number => '4111111111111111', :postal_code => '10101') }
      use_vcr_cassette 'ipcommerce/certification/host/f_d3'

      it "ouputs the result" do
        puts IpcommerceTransaction.new("F_D3", purchase).print
      end
    end
    
    context 'F_D4' do
      let(:amount) { 35.05 }
      let(:credit_card) { Factory.build(:blank_credit_card, :card_number => '5454545454545454', :postal_code => '10101') }
      use_vcr_cassette 'ipcommerce/certification/host/f_d4'

      it "ouputs the result" do
        puts IpcommerceTransaction.new("F_D4", purchase).print
      end
    end   
  end
  
  context 'Voice Authorization Tests' do
    let(:purchase) { gateway.purchase(nil, credit_card, amount, options.merge(:approval_code => '555123')) }
    let(:amount) { 8.00 }
    let(:credit_card) { Factory.build(:blank_credit_card, :card_number => '4111111111111111', :cvv_number => '111') }
    use_vcr_cassette 'ipcommerce/certification/host/f_v1'

    it "F_V1" do
      puts IpcommerceTransaction.new("F_V1", purchase).print
    end
  end
  
  context 'Pre-authorization Tests' do
    let(:authorization) { gateway.authorize(nil, credit_card, amount, options) }
    let(:purchase) { gateway.purchase(nil, credit_card, amount, options) }
    let(:capture) { gateway.capture(authorization.id, amount, options) }
    
    context 'F_F1 - F_F2' do
      let(:amount) { 18.00 }
      let(:credit_card) { Factory.build(:blank_credit_card, :card_number => '371449635398456', :postal_code => '10101') }  
      use_vcr_cassette 'ipcommerce/certification/host/f_f1-f2'
      
      it "ouputs the result" do
        puts IpcommerceTransaction.new("F_F1", authorization).print
        puts IpcommerceTransaction.new("F_F2", capture).print
      end
    end
    
    context 'F_F3 - F_F4' do
      let(:amount) { 13.00 }
      let(:credit_card) { Factory.build(:blank_credit_card, :card_number => '5454545454545454', :postal_code => '10101') }
      use_vcr_cassette 'ipcommerce/certification/host/f_f3-f4'

      it "ouputs the result" do
        puts IpcommerceTransaction.new("F_F3", authorization).print
        puts IpcommerceTransaction.new("F_F4", capture).print
      end
    end
    
    context 'F_F5' do
      let(:amount) { 19.00 }
      let(:credit_card) { Factory.build(:blank_credit_card, :card_number => '4111111111111111', :postal_code => '10101') }
      use_vcr_cassette 'ipcommerce/certification/host/f_f5'

      it "ouputs the result" do
        puts IpcommerceTransaction.new("F_F5", purchase).print
      end
    end
    
    context 'F_F6' do
      let(:amount) { 87.00 }
      let(:credit_card) { Factory.build(:blank_credit_card, :card_number => '4111111111111111', :cvv_number => '111', :postal_code => '10101') }
      use_vcr_cassette 'ipcommerce/certification/host/f_f6'

      it "ouputs the result" do
        puts IpcommerceTransaction.new("F_F6", purchase).print
      end
    end
  end

  context 'Secure Card Data Tokenization Tests' do
    let(:i1_authorization) { gateway.authorize(nil, i1_credit_card, 17.00, options) }
    let(:i1_credit_card) { Factory.build(:blank_credit_card, :card_number => '4111111111111111', :street_address => '1000 1st Av', :postal_code => '10101') }
    let(:i2_authorization) { gateway.authorize(nil, i2_credit_card, 18.00, options) }
    let(:i2_credit_card) { Factory.build(:blank_credit_card, :card_number => '5454545454545454', :cvv_number => '111', :postal_code => '10101') }
    let(:i3_authorization) { gateway.authorize(nil, i3_credit_card, 19.00, options) }
    let(:i3_credit_card) { Factory.build(:blank_credit_card, :card_number => '371449635398456', :cvv_number => '1111', :postal_code => '10101') }
    let(:i4_purchase) { gateway.purchase(nil, i1_credit_card, 16.00, options.merge(:transaction_id => i1_authorization.id)) }
    let(:i5_purchase) { gateway.purchase(nil, i2_credit_card, 18.00, options.merge(:transaction_id => i2_authorization.id)) }
    let(:i6_purchase) { gateway.purchase(nil, i3_credit_card, 31.83, options.merge(:transaction_id => i3_authorization.id)) }
    
    use_vcr_cassette 'ipcommerce/certification/host/f_i1-i6'
    it "outputs the results" do
      puts IpcommerceTransaction.new("F_I1", i1_authorization).print
      puts IpcommerceTransaction.new("F_I2", i2_authorization).print
      puts IpcommerceTransaction.new("F_I3", i3_authorization).print
      puts IpcommerceTransaction.new("F_I4", i4_purchase).print
      puts IpcommerceTransaction.new("F_I5", i5_purchase).print
      puts IpcommerceTransaction.new("F_I6", i6_purchase).print
    end
  end
  
  context 'Transaction Management Services (TMS)' do
    pending
  end
end