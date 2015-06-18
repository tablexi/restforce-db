require_relative "../../../test_helper"

describe Restforce::DB::TimestampCache do

  configure!

  let(:cache) { Restforce::DB::TimestampCache.new }

  let(:timestamp) { Time.now }
  let(:id) { "some-id" }
  let(:record_type) { "CustomObject__c" }
  let(:instance_class) { Struct.new(:id, :record_type, :last_update) }
  let(:instance) { instance_class.new(id, record_type, timestamp) }

  describe "#cache_timestamp" do
    before { cache.cache_timestamp instance }

    it "stores the update timestamp in the cache" do
      expect(cache.timestamp(instance)).to_equal timestamp
    end
  end

  describe "#changed?" do
    let(:new_instance) { instance_class.new(id, record_type, timestamp) }

    describe "when the passed instance was not internally updated" do
      before do
        def new_instance.updated_internally?
          false
        end
      end

      it "returns true" do
        expect(cache).to_be :changed?, new_instance
      end
    end

    describe "when the passed instance was internally updated" do
      before do
        def new_instance.updated_internally?
          true
        end
      end

      describe "but no update timestamp is cached" do

        it "returns true" do
          expect(cache).to_be :changed?, new_instance
        end
      end

      describe "and a recent timestamp is cached" do
        before { cache.cache_timestamp instance }

        it "returns false" do
          expect(cache).to_not_be :changed?, new_instance
        end
      end

      describe "and a stale timestamp is cached" do
        let(:new_instance) { instance_class.new(id, record_type, timestamp + 1) }
        before { cache.cache_timestamp instance }

        it "returns true" do
          expect(cache).to_be :changed?, new_instance
        end
      end
    end
  end

  describe "#reset" do
    before do
      cache.cache_timestamp instance
      cache.reset
    end

    it "retires recently-stored timestamps" do
      expect(cache.timestamp(instance)).to_equal timestamp
    end

    it "expires retired timestamps" do
      cache.reset
      expect(cache.timestamp(instance)).to_be_nil
    end
  end

end
