require_relative "../../../test_helper"

describe Restforce::DB::RecordType do

  configure!

  let(:database_model) { CustomObject }
  let(:salesforce_model) { "CustomObject__c" }
  let!(:record_type) { Restforce::DB::RecordType.new(database_model, salesforce_model) }

  describe "#initialize" do

    it "registers the record type in the master collection" do
      expect(Restforce::DB::RecordType[database_model]).to_equal(record_type)
    end
  end

  describe ".each" do

    # Restforce::DB::RecordType actually implements Enumerable, so we're just
    # going with a trivially testable portion of the Enumerable API.
    it "yields the registered record types" do
      expect(Restforce::DB::RecordType.first).to_equal [database_model.name, record_type]
    end
  end
end
