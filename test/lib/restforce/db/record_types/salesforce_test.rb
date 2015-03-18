require_relative "../../../../test_helper"

describe Restforce::DB::RecordTypes::Salesforce do
  let(:model) { Restforce::DB::RecordTypes::Salesforce.new("CustomObject__c") }
  let(:id) { create!("CustomObject__c") }

  before { login! }

  describe "#find", :vcr do

    it "finds existing records in Salesforce" do
      expect(model.find(id)).to_be_instance_of Restforce::DB::Instances::Salesforce
    end

    it "returns nil when no matching record exists" do
      expect(model.find("a001a000001E1vFAKE")).to_be_nil
    end
  end
end
