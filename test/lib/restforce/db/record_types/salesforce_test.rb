require_relative "../../../../test_helper"

describe Restforce::DB::RecordTypes::Salesforce do

  configure!

  let(:mapping) { Restforce::DB::Mapping.new }
  let(:record_type) { Restforce::DB::RecordTypes::Salesforce.new("CustomObject__c", mapping) }

  describe "#create!", :vcr do
    let(:database_record) do
      CustomObject.create!(
        name: "Something",
        example: "Something else",
      )
    end
    let(:sync_from) { Restforce::DB::Instances::ActiveRecord.new(database_record, mapping) }
    let(:instance) { record_type.create!(sync_from).record }

    before do
      mapping.add_mappings name: "Name", example: "Example_Field__c"
      Salesforce.records << ["CustomObject__c", instance.Id]
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
    let(:id) { Salesforce.create!("CustomObject__c") }

    it "finds existing records in Salesforce" do
      expect(record_type.find(id)).to_be_instance_of Restforce::DB::Instances::Salesforce
    end

    it "returns nil when no matching record exists" do
      expect(record_type.find("a001a000001E1vFAKE")).to_be_nil
    end
  end
end
