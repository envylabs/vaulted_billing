Factory.define :credit_card, :class => VaultedBilling::CreditCard do |c|
  c.expires_on { Date.today + 365 }
  c.card_number { Factory.next :credit_card_number }
  c.cvv_number '123'
  c.first_name { Faker::Name.first_name }
  c.last_name { Faker::Name.last_name }
  c.street_address { Faker::Address.street_address }
  c.locality { Faker::Address.city }
  c.region { Faker::Address.us_state }
  c.postal_code { Faker::Address.zip_code }
  c.country 'US'
  c.phone { Faker::PhoneNumber.phone_number }
end

Factory.define :existing_credit_card, :parent => :credit_card do |c|
  c.vault_id { Factory.next :identifier }
end

Factory.define :ipcommerce_credit_card, :parent => :credit_card do |c|
  c.card_number '5454545454545454'
  c.expires_on Date.new(2010, 12, 31)
  c.region { Faker::Address.state_abbr }
end

Factory.define :invalid_credit_card, :parent => :credit_card do |c|
  c.card_number { Factory.next :invalid_credit_card_number }
end

Factory.define :blank_credit_card, :class => VaultedBilling::CreditCard do |c|
end

Factory.define :terminal_credit_card, :class => VaultedBilling::CreditCard do |c|
  c.expires_on { Date.today + 365 }
end