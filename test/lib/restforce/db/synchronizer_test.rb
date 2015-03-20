require_relative "../../../test_helper"

describe Restforce::DB::Synchronizer do

  configure!

  let(:mapping) { Restforce::DB::Mapping.new(name: "Name", example: "Example_Field__c") }
  let(:database_type) { Restforce::DB::RecordTypes::ActiveRecord.new(CustomObject, mapping) }
  let(:salesforce_type) { Restforce::DB::RecordTypes::Salesforce.new("CustomObject__c", mapping) }
  let(:synchronizer) { Restforce::DB::Synchronizer.new(database_type, salesforce_type) }

  describe "#run", vcr: { match_requests_on: [:method, VCR.request_matchers.uri_without_param(:q)] } do
    let(:attributes) do
      {
        name:    "Custom object",
        example: "Some sample text",
      }
    end
    let(:salesforce_id) do
      Salesforce.create!(
        "CustomObject__c",
        mapping.convert(:salesforce, attributes),
      )
    end

    describe "given an existing Salesforce record" do
      before do
        salesforce_id
        synchronizer.run
      end

      it "populates the database with the new record" do
        record = CustomObject.last

        expect(record.name).to_equal attributes[:name]
        expect(record.example).to_equal attributes[:example]
        expect(record.salesforce_id).to_equal salesforce_id
      end
    end

    describe "given an existing database record" do
      let(:database_record) { CustomObject.create!(attributes) }
      let(:salesforce_id) { database_record.reload.salesforce_id }

      before do
        database_record
        synchronizer.run

        Salesforce.records << ["CustomObject__c", salesforce_id]
      end

      it "populates Salesforce with the new record" do
        record = salesforce_type.find(salesforce_id).record

        expect(record.Name).to_equal attributes[:name]
        expect(record.Example_Field__c).to_equal attributes[:example]
      end
    end

    describe "given a Salesforce record with an existing record in the database" do
      let(:database_record) do
        CustomObject.create!(
          name:          "Some existing name",
          example:       "Some existing sample text",
          salesforce_id: salesforce_id,
        )
      end

      before do
        database_record
        salesforce_id
        synchronizer.run
      end

      it "updates the database record" do
        record = database_record.reload

        expect(record.name).to_equal attributes[:name]
        expect(record.example).to_equal attributes[:example]
      end
    end

  end
end
