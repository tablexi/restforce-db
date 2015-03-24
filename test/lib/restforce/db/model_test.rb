require_relative "../../../test_helper"

describe Restforce::DB::Model do

  configure!

  let(:database_model) { CustomObject }
  let(:salesforce_model) { "CustomObject__c" }
  let(:mappings) do
    {
      name:    "Name",
      example: "Example_Field__c",
    }
  end

  before do
    database_model.send(:include, Restforce::DB::Model)
  end

  describe ".map_to" do
    before do
      database_model.map_to(salesforce_model, mappings)
    end

    it "creates a mapping in Restforce::DB::RecordType" do
      expect(Restforce::DB::RecordType[database_model])
        .to_be_instance_of(Restforce::DB::RecordType)
    end

    it "applies the passed attribute mappings to the registered RecordType" do
      expect(Restforce::DB::RecordType[database_model].mapping.mappings)
        .to_equal(mappings)
    end
  end

  describe ".add_mappings" do
    before do
      database_model.map_to(salesforce_model)
      database_model.add_mappings(mappings)
    end

    it "applies the passed attribute mappings to the registered RecordType" do
      expect(Restforce::DB::RecordType[database_model].mapping.mappings)
        .to_equal(mappings)
    end
  end

end
