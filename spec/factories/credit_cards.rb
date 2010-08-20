Factory.define :credit_card, :class => VaultedBilling::CreditCard do |c|
  c.expires_on { Date.today + 365 }
  c.card_number { Factory.next :credit_card_number }
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
  c.id { Factory.next :identifier }
end
