require_relative "../../../test_helper"

describe Restforce::DB::Synchronizer do
  let(:mapping) { Restforce::DB::Mapping.new(name: "Name", example: "Example_Field__c") }
  let(:database_type) { Restforce::DB::RecordTypes::ActiveRecord.new(CustomObject, mapping) }
  let(:salesforce_type) { Restforce::DB::RecordTypes::Salesforce.new("CustomObject__c", mapping) }
  let(:synchronizer) { Restforce::DB::Synchronizer.new(database_type, salesforce_type) }

  describe "#run", :vcr do

    describe "given an existing Salesforce record" do
      let(:attributes) do
        {
          "Name" => "Custom object",
          "Example_Field__c" => "Some sample text",
        }
      end
      let(:salesforce_id) { create! "CustomObject__c", attributes }

      before do
        login!
        salesforce_id

        synchronizer.run
      end
      after { clean! }

      it "populates the database with the new record" do
        record = CustomObject.last

        expect(record.name).to_equal attributes["Name"]
        expect(record.example).to_equal attributes["Example_Field__c"]
        expect(record.salesforce_id).to_equal salesforce_id
      end
    end

  end
end
