require 'spec_helper'
require_relative 'ipcommerce_transaction.rb'

describe VaultedBilling::Gateways::Ipcommerce do
  let(:gateway) { VaultedBilling.gateway(:ipcommerce).new }
  let(:options) { { :merchant_profile_id => 'TicketTest_C82ED00001', :workflow_id => 'C82ED00001' }} # Terminal Capture: Tsys
  # let(:options) { { :merchant_profile_id => 'TicketTest_B447F00001', :workflow_id => 'B447F00001' }} # Terminal Capture: Vantiv / 5th 3rd Bank

  before(:all) do
    puts "test code, status code, approval code, status message, transaction id"
  end

  context "Authorization Tests" do
    let(:customer) { Factory.build(:customer) } 
    let(:authorization) { gateway.authorize(nil, credit_card, amount, options) }
    
    subject { IpcommerceTransaction.new(code, authorization) }

    context 'V_A1' do
      let(:code) { 'V_A1' }
      let(:amount) { 2.00 }
      let(:credit_card) { Factory.build(:terminal_credit_card, :card_number => '4111111111111111', :cvv_number => '111') }
      use_vcr_cassette 'ipcommerce/certification/terminal/v_a1'
      
      it "outputs the result" do
        puts subject.print
      end
    end
    
    context 'V_A2' do
      let(:code) { 'V_A2' }
      let(:amount) { 2.50 }
      let(:credit_card) { Factory.build(:terminal_credit_card, :card_number => '5454545454545454', :cvv_number => '111') }
      use_vcr_cassette 'ipcommerce/certification/terminal/v_a2'
      
      it "outputs the result" do
        puts subject.print
      end
    end

    context 'V_A3' do
      let(:code) { 'V_A3' }
      let(:amount) { 5.00 }
      let(:credit_card) { Factory.build(:terminal_credit_card, :card_number => '371449635398456', :cvv_number => '1111') }
      use_vcr_cassette 'ipcommerce/certification/terminal/v_a3'
      
      it "outputs the result" do
        puts subject.print
      end
    end
    
    context 'V_A4' do
      let(:code) { 'V_A4' }
      let(:amount) { 6.00 }
      let(:credit_card) { Factory.build(:terminal_credit_card, :card_number => '4111111111111111', :cvv_number => '111') }
      use_vcr_cassette 'ipcommerce/certification/terminal/v_a4'
      
      it "outputs the result" do
        puts subject.print
      end
    end

    context 'V_A5' do
      let(:code) { 'V_A5' }
      let(:amount) { 2.15 }
      let(:credit_card) { Factory.build(:terminal_credit_card, :card_number => '5454545454545454', :cvv_number => nil, :postal_code => Faker::Address.zip_code) }
      use_vcr_cassette 'ipcommerce/certification/terminal/v_a5'

      it "outputs the result" do
        puts subject.print
      end
    end

    context 'V_A6' do
      let(:code) { 'V_A6' }
      let(:amount) { 10.83 }
      let(:credit_card) { Factory.build(:terminal_credit_card, :card_number => '371449635398456', :cvv_number => 777) }
      use_vcr_cassette 'ipcommerce/certification/terminal/v_a6'

      it "outputs the result" do
        puts subject.print
      end
    end
    
    context 'V_A7' do
      let(:capture_all) { gateway.capture_all(options) }
      use_vcr_cassette 'ipcommerce/certification/terminal/v_a7'

      it "outputs the results" do
        puts IpcommerceTransaction.new("V_A7", capture_all).print
      end
    end
  end

  context "ReturnById Tests" do
    let(:authorization) { gateway.authorize(nil, credit_card, amount, options) }
    let(:capture_selective) { gateway.capture_selective([authorization.id], nil, options) }
    let(:refund) { gateway.refund(authorization.id, refund_amount, options) }

    context 'V_B1 - V_B3' do
      let(:amount) { 49.00 }
      let(:capture_amount) { amount }
      let(:refund_amount) { 32.00 }
      let(:credit_card) { Factory.build(:terminal_credit_card, :card_number => '4111111111111111', :cvv_number => '111') }
      
      use_vcr_cassette 'ipcommerce/certification/terminal/v_b1-3'
      
      subject { authorization }
      
      it "outputs the result" do
        puts IpcommerceTransaction.new("V_B1", authorization).print
        puts IpcommerceTransaction.new("V_B2", capture_selective).print
        puts IpcommerceTransaction.new("V_B3", refund).print
      end
    end
    
    context 'V_B4 - V_B8' do
      let(:amount) { 27.00 }
      let(:capture_amount) { amount }
      let(:refund_amount) { amount }
      let(:credit_card) { Factory.build(:terminal_credit_card, :card_number => '5454545454545454', :cvv_number => '111') }
      
      let(:return_unlinked) { gateway.return_unlinked(nil, unlinked_credit_card, 3.00, options) }
      let(:unlinked_credit_card) { Factory.build(:terminal_credit_card, :card_number => '5454545454545454') }
      use_vcr_cassette 'ipcommerce/certification/terminal/v_b4-8'
      
      subject { authorization }
      
      it "outputs the result" do
        puts IpcommerceTransaction.new("V_B4", authorization).print
        puts IpcommerceTransaction.new("V_B5", gateway.capture_all(options)).print
        puts IpcommerceTransaction.new("V_B6", refund).print
        puts IpcommerceTransaction.new("V_B7", return_unlinked).print
        puts IpcommerceTransaction.new("V_B8", gateway.capture_all(options)).print
      end
    end
  end
  
  context "Undo (Void) Tests" do
    let(:c1_authorization) { gateway.authorize(nil, c1_credit_card, 57.00, options) }
    let(:c1_credit_card) { Factory.build(:terminal_credit_card, :card_number => '5454545454545454', :cvv_number => '111') }
    let(:c2_void) { gateway.void(c1_authorization.id, options) }
    let(:c3_authorization) { gateway.authorize(nil, c3_credit_card, 54.00, options) }
    let(:c3_credit_card) { Factory.build(:terminal_credit_card, :card_number => '4111111111111111', :cvv_number => '111') }
    let(:c4_capture_selective) { gateway.capture_selective([c3_authorization.id], nil, options) }
    let(:c5_authorization) { gateway.authorize(nil, c5_credit_card, 61.00, options) }
    let(:c5_credit_card) { Factory.build(:terminal_credit_card, :card_number => '5454545454545454', :cvv_number => '111') }
    let(:c6_void) { gateway.void(c5_authorization.id, options) }
    let(:c7_authorization) { gateway.authorize(nil, c3_credit_card, 63.00, options) }

    use_vcr_cassette 'ipcommerce/certification/terminal/v_c'
      
    it "outputs the result" do
      puts IpcommerceTransaction.new("V_C1", c1_authorization).print
      puts IpcommerceTransaction.new("V_C2", c2_void).print
      puts IpcommerceTransaction.new("V_C3", c3_authorization).print
      puts IpcommerceTransaction.new("V_C4", c4_capture_selective).print
      puts IpcommerceTransaction.new("V_C5", c5_authorization).print
      puts IpcommerceTransaction.new("V_C6", c6_void).print
      puts IpcommerceTransaction.new("V_C7", c7_authorization).print
      puts IpcommerceTransaction.new("V_C8", gateway.capture_all(options)).print
    end
  end
  
  context "Non-Standard Card Tests" do
    let(:d1_authorization) { gateway.authorize(nil, d1_credit_card, 17.00, options) }
    let(:d1_credit_card) { Factory.build(:terminal_credit_card, :card_number => '6011000995504101', :cvv_number => '111') }
    let(:d2_authorization) { gateway.authorize(nil, d2_credit_card, 33.03, options) }
    let(:d2_credit_card) { Factory.build(:terminal_credit_card, :card_number => '4111111111111111') }
    let(:d3_authorization) { gateway.authorize(nil, d2_credit_card, 34.02, options) }
    
    let(:d4_authorization) { gateway.authorize(nil, d4_credit_card, 35.05, options) }
    let(:d4_credit_card) { Factory.build(:terminal_credit_card, :card_number => '5454545454545454') }

    use_vcr_cassette 'ipcommerce/certification/terminal/v_d'
      
    it "outputs the result" do
      puts IpcommerceTransaction.new("V_D1", d1_authorization).print
      puts IpcommerceTransaction.new("V_D2", d2_authorization).print
      puts IpcommerceTransaction.new("V_D3", d3_authorization).print
      puts IpcommerceTransaction.new("V_D4", d4_authorization).print
      puts IpcommerceTransaction.new("V_D5", gateway.capture_all(options)).print
    end
  end


  context "Voice Authorization Tests" do
    let(:v1_authorization) { gateway.authorize(nil, v1_credit_card, 8.00, options.merge(:approval_code => 'ABC123')) }
    let(:v1_credit_card) { Factory.build(:terminal_credit_card, :card_number => '4111111111111111') }

    use_vcr_cassette 'ipcommerce/certification/terminal/v_v'
 
    it "outputs the result" do
      puts IpcommerceTransaction.new("V_V1", v1_authorization).print
      puts IpcommerceTransaction.new("V_V2", gateway.capture_all(options)).print
    end
  end
  
  
  context "Secure Card Data Tokenization Tests" do
    let(:i1_authorization) { gateway.authorize(nil, i1_credit_card, 1.00, options) }
    let(:i1_credit_card) { Factory.build(:terminal_credit_card, :card_number => '4111111111111111', :street_address => '1000 1st Av', :postal_code => '10101') }
    let(:i2_authorization) { gateway.authorize(nil, i2_credit_card, 1.00, options) }
    let(:i2_credit_card) { Factory.build(:terminal_credit_card, :card_number => '5454545454545454', :cvv_number => '111') }
    let(:i3_authorization) { gateway.authorize(nil, i3_credit_card, 1.00, options) }
    let(:i3_credit_card) { Factory.build(:terminal_credit_card, :card_number => '371449635398456', :cvv_number => '1111') }
    let(:i5_authorization) { gateway.authorize(nil, i1_credit_card, 16.00, options) }
    let(:i6_refund) { gateway.refund(i5_authorization.id, 18.00, options) }
    let(:i7_authorization) { gateway.authorize(nil, i3_credit_card, 31.83, options) }

    use_vcr_cassette 'ipcommerce/certification/terminal/v_i'
      
    it "outputs the result" do
      puts IpcommerceTransaction.new("V_I1", i1_authorization).print
      puts IpcommerceTransaction.new("V_I2", i2_authorization).print 
      puts IpcommerceTransaction.new("V_I3", i3_authorization).print 
      puts IpcommerceTransaction.new("V_I4", gateway.capture_all(options)).print
      puts IpcommerceTransaction.new("V_I5", i5_authorization).print
      puts IpcommerceTransaction.new("V_I6", i6_refund).print
      puts IpcommerceTransaction.new("V_I7", i7_authorization).print
      puts IpcommerceTransaction.new("V_I8", gateway.capture_all(options)).print
    end
  end
end