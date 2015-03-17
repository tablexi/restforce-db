require_relative "../../../../test_helper"

describe Restforce::DB::Models::Salesforce do
  let(:model) { Restforce::DB::Models::Salesforce.new("CustomObject__c") }
  let(:id) { create!("CustomObject__c") }

  before { login! }

  describe "#find", :vcr do

    it "finds existing records in Salesforce" do
      model.find(id).must_be_instance_of Restforce::DB::Instances::Salesforce
    end

    it "returns nil when no matching record exists" do
      model.find("a001a000001E1vFAKE").must_be_nil
    end
  end
end
