require_relative "../../../../test_helper"

describe Restforce::DB::Associations::HasOne do

  configure!
  mappings!

  let(:association) { Restforce::DB::Associations::HasOne.new(:custom_object, through: "Friend__c") }

  it "sets the lookup field" do
    expect(association.lookup).to_equal "Friend__c"
  end

  describe "#fields" do

    it "returns nothing (since the lookup field is external)" do
      expect(association.fields).to_equal []
    end
  end
end
