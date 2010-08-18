module SpecHelper
  def freeze_time(time=nil)
    (time ||= Time.now).tap { |now| Time.stub(:now).and_return(now) }
  end

  shared_examples_for "a transaction request" do
    it 'returns a Transaction' do
      subject.result.should be_kind_of(VaultedBilling::Transaction)
    end

    it 'returns a Transaction with an identifier' do
      subject.result.id.should_not be_blank
    end
  end
end
