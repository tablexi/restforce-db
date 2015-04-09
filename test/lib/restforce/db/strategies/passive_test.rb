require_relative "../../../../test_helper"

describe Restforce::DB::Strategies::Passive do
  let(:strategy) { Restforce::DB::Strategies::Passive.new }

  it "is a passive strategy" do
    expect(strategy).to_be :passive?
  end

  describe "#build?" do

    it "returns false for any record" do
      record = Object.new
      expect(strategy.build?(record)).to_equal false
    end
  end
end
