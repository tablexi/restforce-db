require_relative "../../../../test_helper"

describe Restforce::DB::RecordTypes::ActiveRecord do
  let(:mapping) { Restforce::DB::Mapping.new }
  let(:record_type) { Restforce::DB::RecordTypes::ActiveRecord.new(CustomObject, mapping) }
  let(:salesforce_id) { "a001a000001E1vREAL" }

  describe "#create!" do
    let(:create_from) do
      Struct.new(:id, :attributes).new(
        salesforce_id,
        "Name" => "Some name",
        "Example_Field__c" => "Some text",
      )
    end
    let(:instance) { record_type.create!(create_from).record }

    before do
      mapping.add_mappings(name: "Name", example: "Example_Field__c")
    end

    it "creates a record in the database from the passed Salesforce record's attributes" do
      expect(instance.salesforce_id).to_equal salesforce_id
      expect(instance.name).to_equal create_from.attributes["Name"]
      expect(instance.example).to_equal create_from.attributes["Example_Field__c"]
    end
  end

  describe "#find" do

    it "finds existing records in the database by their salesforce id" do
      CustomObject.create!(salesforce_id: salesforce_id)
      expect(record_type.find(salesforce_id)).to_be_instance_of Restforce::DB::Instances::ActiveRecord
    end

    it "returns nil when no matching record exists" do
      expect(record_type.find("a001a000001E1vFAKE")).to_be_nil
    end
  end
end
