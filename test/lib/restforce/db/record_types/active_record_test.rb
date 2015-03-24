require_relative "../../../../test_helper"

describe Restforce::DB::RecordTypes::ActiveRecord do

  configure!

  let(:mapping) { Restforce::DB::Mapping.new }
  let(:record_type) { Restforce::DB::RecordTypes::ActiveRecord.new(CustomObject, mapping) }
  let(:salesforce_id) { "a001a000001E1vREAL" }

  describe "#sync!" do
    let(:sync_from) do
      Struct.new(:id, :last_update, :attributes).new(
        salesforce_id,
        Time.now,
        name:    "Some name",
        example: "Some text",
      )
    end
    let(:instance) { record_type.sync!(sync_from).record }

    before do
      mapping.add_mappings(name: "Name", example: "Example_Field__c")
    end

    describe "without an existing database record" do

      it "creates a new database record from the passed Salesforce record" do
        expect(instance.salesforce_id).to_equal salesforce_id
        expect(instance.name).to_equal sync_from.attributes[:name]
        expect(instance.example).to_equal sync_from.attributes[:example]
        expect(instance.synchronized_at).to_not_be_nil
      end
    end

    describe "with an existing database record" do
      let!(:sync_to) do
        CustomObject.create!(
          name:            "Existing name",
          example:         "Existing sample text",
          salesforce_id:   salesforce_id,
          synchronized_at: Time.now,
        )
      end

      it "updates the existing database record" do
        expect(instance).to_equal sync_to.reload
        expect(instance.name).to_equal sync_from.attributes[:name]
        expect(instance.example).to_equal sync_from.attributes[:example]
        expect(instance.synchronized_at).to_not_be_nil
      end
    end
  end

  describe "#create!" do
    let(:create_from) do
      Struct.new(:id, :last_update, :attributes).new(
        salesforce_id,
        Time.now,
        name:    "Some name",
        example: "Some text",
      )
    end
    let(:instance) { record_type.create!(create_from).record }

    before do
      mapping.add_mappings(name: "Name", example: "Example_Field__c")
    end

    it "creates a record in the database from the passed Salesforce record's attributes" do
      expect(instance.salesforce_id).to_equal salesforce_id
      expect(instance.name).to_equal create_from.attributes[:name]
      expect(instance.example).to_equal create_from.attributes[:example]
      expect(instance.synchronized_at).to_not_be_nil
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
