require_relative "../../../../test_helper"

describe Restforce::DB::Strategies::Passive do

  configure!

  let(:strategy) { Restforce::DB::Strategies::Passive.new }

  it "is a passive strategy" do
    expect(strategy).to_be :passive?
  end

  describe "#build?" do

    it "returns false for any record" do
      record = Object.new
      expect(strategy).to_not_be :build?, record
    end
  end
end
