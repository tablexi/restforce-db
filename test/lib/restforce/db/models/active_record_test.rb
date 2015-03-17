require_relative "../../../../test_helper"

describe Restforce::DB::Models::ActiveRecord do
  let(:model) { Restforce::DB::Models::ActiveRecord.new(CustomObject) }
  let(:id) { "a001a000001E1vREAL" }

  describe "#find" do

    it "finds existing records in the database by their salesforce id" do
      CustomObject.create!(salesforce_id: id)
      expect(model.find(id)).to_be_instance_of Restforce::DB::Instances::ActiveRecord
    end

    it "returns nil when no matching record exists" do
      expect(model.find("a001a000001E1vFAKE")).to_be_nil
    end
  end
end
