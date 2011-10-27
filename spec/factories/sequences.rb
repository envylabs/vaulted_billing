require 'digest/md5'

Factory.sequence :identifier do |i|
  Digest::MD5.hexdigest("---#{Time.now.to_f}---#{$$}--#{rand(10_000_000)}---#{rand(10_000)}")
end

Factory.sequence :credit_card_number do |c|
  cards = %w(
    5561825156630626 5120186265015108 5439365422152873
    5285948609760819 5459804026655480 5245621729327509
    5228208711376826 5511194136987213 5230002140732287
    5288407810509231 4539244255469542 4532409240022071
    4556960115460938 4539482164563803 4024007199960179
    4913379750143840 4716016665352277 4838202546066137
    4024007191655199 4033649363642395 348690499380524
    346897195593746 375446305355283 343364053762320
  )
  cards[rand(cards.size)]
end

Factory.sequence(:invalid_credit_card_number) { |c| '4111111111111112' }
Factory.sequence(:failure_credit_card_number) { |c| VaultedBilling::Gateways::Bogus::FailureCards[rand(VaultedBilling::Gateways::Bogus::FailureCards.size)] }
