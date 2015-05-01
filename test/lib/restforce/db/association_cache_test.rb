require_relative "../../../test_helper"

describe Restforce::DB::AssociationCache do

  configure!

  let(:cache) { Restforce::DB::AssociationCache.new }
  let(:database_model) { CustomObject }
  let(:lookups) { { salesforce_id: "a001a000001E1vREAL" } }
  let(:record) { database_model.new(lookups) }

  describe "#<<" do
    before do
      cache << record
    end

    it "caches the appended record by class" do
      expect(cache.cache[database_model]).to_equal [record]
    end
  end

  describe "#find" do
    let(:found) { cache.find(database_model, lookups) }

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

    describe "when a record of another class has been added with the same lookups" do
      before do
        cache << User.new(lookups)
      end

      it "returns nil" do
        expect(found).to_be_nil
      end
    end

    describe "when no record has been added or persisted" do

      it "returns nil" do
        expect(found).to_be_nil
      end
    end
  end

end
