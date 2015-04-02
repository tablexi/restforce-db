require_relative "../../../test_helper"

describe Restforce::DB::Model do

  configure!

  let(:database_model) { CustomObject }
  let(:salesforce_model) { "CustomObject__c" }
  let(:fields) do
    {
      name:    "Name",
      example: "Example_Field__c",
    }
  end

  before do
    database_model.send(:include, Restforce::DB::Model)
  end

  describe ".sync_with" do
    before do
      database_model.sync_with(salesforce_model, fields: fields)
    end

    it "creates a mapping in Restforce::DB::Mapping" do
      expect(Restforce::DB::Mapping[database_model]).to_not_be :empty?
    end
  end

end
