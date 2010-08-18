Factory.define :customer, :class => VaultedBilling::Customer do |c|
  c.after_build do |customer|
    customer.id = Factory.next(:identifier)
  end
end
