Factory.define :credit_card, :class => VaultedBilling::CreditCard do |c|
  c.after_build do |credit_card|
    credit_card.id = Factory.next(:identifier)
  end
end
