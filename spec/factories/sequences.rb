require 'digest/md5'

Factory.sequence :identifier do |i|
  Digest::MD5.hexdigest("---#{Time.now.to_f}---#{$$}--#{rand(10_000_000)}---#{rand(10_000)}")
end
