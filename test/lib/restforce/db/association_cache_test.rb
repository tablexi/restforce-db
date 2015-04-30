require_relative "../../../test_helper"

describe Restforce::DB::AssociationCache do

  configure!

  let(:cache) { Restforce::DB::AssociationCache.new }
  let(:database_model) { CustomObject }
  let(:lookups) { { salesforce_id: "a001a000001E1vREAL" } }
  let(:record) { database_model.new(lookups) }
  let(:found) { cache.find(database_model, lookups) }

  describe "#find" do

    describe "when the record has been added to the cache" do
      before do
        cache << record
      end

      it "finds the record" do
        expect(found).to_equal record
      end
    end

    describe "when the record has been persisted" do
      before do
        record.save!
      end

      it "finds the persisted record by its lookups" do
        expect(found).to_equal record
      end
    end

    describe "when no record has been added or persisted" do

      it "returns nil" do
        expect(found).to_be_nil
      end
    end
  end

  describe "#<<" do
    before do
      cache << record
    end

    it "adds the record to the cache" do
      expect(found).to_equal record
    end
  end

end
