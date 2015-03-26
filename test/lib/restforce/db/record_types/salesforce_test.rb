require_relative "../../../../test_helper"

describe Restforce::DB::RecordTypes::Salesforce do

  configure!
  mappings!

  let(:record_type) { mapping.salesforce_record_type }

  describe "#create!", :vcr do
    let(:database_record) do
      database_model.create!(
        name: "Something",
        example: "Something else",
      )
    end
    let(:sync_from) { Restforce::DB::Instances::ActiveRecord.new(database_model, database_record, mapping) }
    let(:instance) { record_type.create!(sync_from).record }

    before do
      Salesforce.records << [salesforce_model, instance.Id]
    end

    it "creates a record in Salesforce from the passed database record's attributes" do
      expect(instance.Name).to_equal database_record.name
      expect(instance.Example_Field__c).to_equal database_record.example
    end

    it "updates the database record with the Salesforce record's ID" do
      expect(sync_from.synced?).to_equal(true)
    end
  end

  describe "#find", :vcr do
    let(:id) { Salesforce.create!(salesforce_model) }

    it "finds existing records in Salesforce" do
      expect(record_type.find(id)).to_be_instance_of Restforce::DB::Instances::Salesforce
    end

    it "returns nil when no matching record exists" do
      expect(record_type.find("a001a000001E1vFAKE")).to_be_nil
    end
  end
end
