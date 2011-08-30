require 'spec_helper'
require_relative 'ipcommerce_transaction.rb'

describe VaultedBilling::Gateways::Ipcommerce do
  let(:gateway) { VaultedBilling.gateway(:ipcommerce).new }
  let(:options) { { :merchant_profile_id => 'TicketTest_C82ED00001', :workflow_id => 'C82ED00001' }} # Terminal Capture: Tsys
  let(:batch) { "T" }
  
  # let(:options) { { :merchant_profile_id => 'TicketTest_B447F00001', :workflow_id => 'B447F00001' }} # Terminal Capture: Vantiv / 5th 3rd Bank
  # let(:batch) { "V" }


  before(:all) do
    puts "test code, status code, approval code, status message, transaction id"
  end

  context "Authorization Tests" do
    let(:customer) { Factory.build(:customer) } 
    let(:authorization) { gateway.authorize(nil, credit_card, amount, options) }
    
    subject { IpcommerceTransaction.new(code, authorization) }

    context 'setup' do
      use_vcr_cassette 'ipcommerce/certification/terminal/a-setup'
      it "clears captures" do
        gateway.capture_all(options)
      end
    end

    context 'A1' do
      let(:code) { "#{batch}_A1" }
      let(:amount) { 2.00 }
      let(:credit_card) { Factory.build(:expires_credit_card, :card_number => '4111111111111111', :cvv_number => '111', :postal_code => '10101') }
      use_vcr_cassette 'ipcommerce/certification/terminal/a1'


      it "outputs the result" do
        puts subject.print
      end
    end
    
    context 'A2' do
      let(:code) { "#{batch}_A2" }
      let(:amount) { 2.50 }
      let(:credit_card) { Factory.build(:expires_credit_card, :card_number => '5454545454545454', :cvv_number => '111', :postal_code => '10101') }
      use_vcr_cassette 'ipcommerce/certification/terminal/a2'
      
      it "outputs the result" do
        puts subject.print
      end
    end

    context 'A3' do
      let(:code) { "#{batch}_A3" }
      let(:amount) { 5.00 }
      let(:credit_card) { Factory.build(:expires_credit_card, :card_number => '371449635398456', :cvv_number => '1111', :postal_code => '10101') }
      use_vcr_cassette 'ipcommerce/certification/terminal/a3'
      
      it "outputs the result" do
        puts subject.print
      end
    end
    
    context 'A4' do
      let(:code) { "#{batch}_A4" }
      let(:amount) { 6.00 }
      let(:credit_card) { Factory.build(:expires_credit_card, :card_number => '4111111111111111', :cvv_number => '111', :postal_code => '10101') }
      use_vcr_cassette 'ipcommerce/certification/terminal/a4'
      
      it "outputs the result" do
        puts subject.print
      end
    end

    context 'A5' do
      let(:code) { "#{batch}_A5" }
      let(:amount) { 2.15 }
      let(:credit_card) { Factory.build(:expires_credit_card, :card_number => '5454545454545454', :cvv_number => nil, :postal_code => '10101') }
      use_vcr_cassette 'ipcommerce/certification/terminal/a5'

      it "outputs the result" do
        puts subject.print
      end
    end

    context 'A6' do
      let(:code) { "#{batch}_A6" }
      let(:amount) { 10.83 }
      let(:credit_card) { Factory.build(:expires_credit_card, :card_number => '371449635398456', :cvv_number => 777, :postal_code => '10101') }
      use_vcr_cassette 'ipcommerce/certification/terminal/a6'

      it "outputs the result" do
        puts subject.print
      end
    end
    
    context 'A7' do
      let(:capture_all) { gateway.capture_all(options) }
      use_vcr_cassette 'ipcommerce/certification/terminal/a7'

      it "outputs the results" do
        puts IpcommerceTransaction.new("#{batch}_A7", capture_all).print
      end
    end
  end

  context "ReturnById Tests" do
    let(:b1_authorization) { gateway.authorize(nil, b1_credit_card, 49.00, options) }
    let(:b1_credit_card) { Factory.build(:expires_credit_card, :card_number => '4111111111111111', :cvv_number => '111', :postal_code => '10101') }
    let(:b2_capture_selective) { gateway.capture_selective([b1_authorization.id], nil, options) }
    let(:b3_refund) { gateway.refund(b1_authorization.id, 32.00, options) }
    let(:b4_authorization) { gateway.authorize(nil, b4_credit_card, 27.00, options) }
    let(:b4_credit_card) { Factory.build(:expires_credit_card, :card_number => '5454545454545454', :cvv_number => '111', :postal_code => '10101') }
    let(:b6_refund) { gateway.refund(b4_authorization.id, 27.00, options) }
    let(:b7_return_unlinked) { gateway.return_unlinked(nil, unlinked_credit_card, 3.00, options) }
    let(:unlinked_credit_card) { Factory.build(:expires_credit_card, :card_number => '5454545454545454') }

    use_vcr_cassette 'ipcommerce/certification/terminal/b'

    context 'setup' do
      use_vcr_cassette 'ipcommerce/certification/terminal/b-setup'
      it "clears captures" do
        gateway.capture_all(options)
      end
    end
        
    it "outputs the result" do
      puts IpcommerceTransaction.new("#{batch}_B1", b1_authorization).print
      puts IpcommerceTransaction.new("#{batch}_B2", b2_capture_selective).print
      puts IpcommerceTransaction.new("#{batch}_B3", b3_refund).print
      puts IpcommerceTransaction.new("#{batch}_B4", b4_authorization).print
      puts IpcommerceTransaction.new("#{batch}_B5", gateway.capture_all(options)).print
      puts IpcommerceTransaction.new("#{batch}_B6", b6_refund).print
      puts IpcommerceTransaction.new("#{batch}_B7", b7_return_unlinked).print
      puts IpcommerceTransaction.new("#{batch}_B8", gateway.capture_all(options)).print
    end
  end
  
  context "Undo (Void) Tests" do
    let(:c1_authorization) { gateway.authorize(nil, c1_credit_card, 57.00, options) }
    let(:c1_credit_card) { Factory.build(:expires_credit_card, :card_number => '5454545454545454', :cvv_number => '111', :postal_code => '10101') }
    let(:c2_void) { gateway.void(c1_authorization.id, options) }
    let(:c3_authorization) { gateway.authorize(nil, c3_credit_card, 54.00, options) }
    let(:c3_credit_card) { Factory.build(:expires_credit_card, :card_number => '4111111111111111', :cvv_number => '111', :postal_code => '10101') }
    let(:c4_capture_selective) { gateway.capture_selective([c3_authorization.id], nil, options) }
    let(:c5_authorization) { gateway.authorize(nil, c5_credit_card, 61.00, options) }
    let(:c5_credit_card) { Factory.build(:expires_credit_card, :card_number => '5454545454545454', :cvv_number => '111', :postal_code => '10101') }
    let(:c6_void) { gateway.void(c5_authorization.id, options) }
    let(:c7_authorization) { gateway.authorize(nil, c3_credit_card, 63.00, options) }
    let(:c7_credit_card) { Factory.build(:expires_credit_card, :card_number => '4111111111111111', :cvv_number => '111', :postal_code => '10101') }

    use_vcr_cassette 'ipcommerce/certification/terminal/c'

    context 'setup' do
      use_vcr_cassette 'ipcommerce/certification/terminal/c-setup'
      it "clears captures" do
        gateway.capture_all(options)
      end
    end
    
    it "outputs the result" do
      puts IpcommerceTransaction.new("#{batch}_C1", c1_authorization).print
      puts IpcommerceTransaction.new("#{batch}_C2", c2_void).print
      puts IpcommerceTransaction.new("#{batch}_C3", c3_authorization).print
      puts IpcommerceTransaction.new("#{batch}_C4", c4_capture_selective).print
      puts IpcommerceTransaction.new("#{batch}_C5", c5_authorization).print
      puts IpcommerceTransaction.new("#{batch}_C6", c6_void).print
      puts IpcommerceTransaction.new("#{batch}_C7", c7_authorization).print
      puts IpcommerceTransaction.new("#{batch}_C8", gateway.capture_all(options)).print
    end
  end
  
  context "Non-Standard Card Tests" do
    let(:d1_authorization) { gateway.authorize(nil, d1_credit_card, 17.00, options) }
    let(:d1_credit_card) { Factory.build(:expires_credit_card, :card_number => '6011000995504101', :cvv_number => '111', :postal_code => '10101') }
    let(:d2_authorization) { gateway.authorize(nil, d2_credit_card, 33.03, options) }
    let(:d2_credit_card) { Factory.build(:expires_credit_card, :card_number => '4111111111111111', :postal_code => '10101') }
    let(:d3_authorization) { gateway.authorize(nil, d3_credit_card, 34.02, options) }    
    let(:d3_credit_card) { Factory.build(:expires_credit_card, :card_number => '4111111111111111', :postal_code => '10101') }
    let(:d4_authorization) { gateway.authorize(nil, d4_credit_card, 35.05, options) }
    let(:d4_credit_card) { Factory.build(:expires_credit_card, :card_number => '5454545454545454', :postal_code => '10101') }

    use_vcr_cassette 'ipcommerce/certification/terminal/d'
  
    context 'setup' do
      use_vcr_cassette 'ipcommerce/certification/terminal/d-setup'
      it "clears captures" do
        gateway.capture_all(options)
      end
    end

    it "outputs the result" do
      puts IpcommerceTransaction.new("#{batch}_D1", d1_authorization).print
      puts IpcommerceTransaction.new("#{batch}_D2", d2_authorization).print
      puts IpcommerceTransaction.new("#{batch}_D3", d3_authorization).print
      puts IpcommerceTransaction.new("#{batch}_D4", d4_authorization).print
      puts IpcommerceTransaction.new("#{batch}_D5", gateway.capture_all(options)).print
    end
  end


  context "Voice Authorization Tests" do
    let(:v1_authorization) { gateway.authorize(nil, v1_credit_card, 8.00, options.merge(:approval_code => 'ABC123')) }
    let(:v1_credit_card) { Factory.build(:expires_credit_card, :card_number => '4111111111111111') }

    use_vcr_cassette 'ipcommerce/certification/terminal/v'
 
    context 'setup' do
      use_vcr_cassette 'ipcommerce/certification/terminal/v-setup'
      it "clears captures" do
        gateway.capture_all(options)
      end
    end
 
    it "outputs the result" do
      puts IpcommerceTransaction.new("#{batch}_V1", v1_authorization).print
      puts IpcommerceTransaction.new("#{batch}_V2", gateway.capture_all(options)).print
    end
  end
  
  
  context "Secure Card Data Tokenization Tests" do
    let(:i1_authorization) { gateway.authorize(nil, i1_credit_card, 1.00, options) }
    let(:i1_credit_card) { Factory.build(:expires_credit_card, :card_number => '4111111111111111', :street_address => '1000 1st Av', :postal_code => '10101') }
    let(:i2_authorization) { gateway.authorize(nil, i2_credit_card, 1.00, options) }
    let(:i2_credit_card) { Factory.build(:expires_credit_card, :card_number => '5454545454545454', :cvv_number => '111', :postal_code => '10101') }
    let(:i3_authorization) { gateway.authorize(nil, i3_credit_card, 1.00, options) }
    let(:i3_credit_card) { Factory.build(:expires_credit_card, :card_number => '371449635398456', :cvv_number => '1111', :postal_code => '10101') }
    let(:i5_authorization) { gateway.authorize(nil, i1_credit_card, 16.00, options) }
    let(:i6_return_unlinked) { gateway.return_unlinked(nil, i1_credit_card, 18.00, options) }
    let(:i7_authorization) { gateway.authorize(nil, i3_credit_card, 31.83, options) }

    use_vcr_cassette 'ipcommerce/certification/terminal/i'
    
    context 'setup' do
      use_vcr_cassette 'ipcommerce/certification/terminal/i-setup'
      it "clears captures" do
        gateway.capture_all(options)
      end
    end

    it "outputs the result" do
      puts IpcommerceTransaction.new("#{batch}_I1", i1_authorization).print
      puts IpcommerceTransaction.new("#{batch}_I2", i2_authorization).print 
      puts IpcommerceTransaction.new("#{batch}_I3", i3_authorization).print 
      puts IpcommerceTransaction.new("#{batch}_I4", gateway.capture_all(options)).print
      puts IpcommerceTransaction.new("#{batch}_I5", i5_authorization).print
      puts IpcommerceTransaction.new("#{batch}_I6", i6_return_unlinked).print
      puts IpcommerceTransaction.new("#{batch}_I7", i7_authorization).print
      puts IpcommerceTransaction.new("#{batch}_I8", gateway.capture_all(options)).print
    end
  end
end