require_relative "../../../test_helper"

describe Restforce::DB::Strategy do

  describe ".for" do
    let(:strategy) { Restforce::DB::Strategy.for(type) }

    describe ":always" do
      let(:type) { :always }
      it { expect(strategy).to_be_instance_of(Restforce::DB::Strategies::Always) }
    end

    describe ":always" do
      let(:type) { :passive }
      it { expect(strategy).to_be_instance_of(Restforce::DB::Strategies::Passive) }
    end
  end

end
