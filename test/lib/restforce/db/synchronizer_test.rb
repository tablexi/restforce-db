require_relative "../../../test_helper"

describe Restforce::DB::Synchronizer do

  configure!

  let(:mapping) { Restforce::DB::Mapping.new(name: "Name", example: "Example_Field__c") }
  let(:database_type) { Restforce::DB::RecordTypes::ActiveRecord.new(CustomObject, mapping) }
  let(:salesforce_type) { Restforce::DB::RecordTypes::Salesforce.new("CustomObject__c", mapping) }
  let(:synchronizer) { Restforce::DB::Synchronizer.new(database_type, salesforce_type) }

  describe "#run", :vcr do
    let(:attributes) do
      {
        "Name" => "Custom object",
        "Example_Field__c" => "Some sample text",
      }
    end
    let(:salesforce_id) { Salesforce.create! "CustomObject__c", attributes }

    describe "given an existing Salesforce record" do
      before do
        salesforce_id
        synchronizer.run
      end

      it "populates the database with the new record" do
        record = CustomObject.last

        expect(record.name).to_equal attributes["Name"]
        expect(record.example).to_equal attributes["Example_Field__c"]
        expect(record.salesforce_id).to_equal salesforce_id
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

        expect(record.name).to_equal attributes["Name"]
        expect(record.example).to_equal attributes["Example_Field__c"]
      end
    end

  end
end
