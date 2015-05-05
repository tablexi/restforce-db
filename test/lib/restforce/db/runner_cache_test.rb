require_relative "../../../test_helper"

describe Restforce::DB::RunnerCache do

  configure!
  mappings!

  let(:cache) { Restforce::DB::RunnerCache.new }

  describe "#collection" do
    let(:object) { mapping.database_model.create! }

    before { object }

    it "invokes the specified collection for the mapping" do
      instances = cache.collection(mapping, :database_record_type)
      expect(instances.first.record).to_equal object
    end

    describe "on repeated calls for the same mapping" do
      let(:dummy_collection) do
        Object.new.tap do |collection|

          def collection.values
            [1, 2, 3]
          end

          def collection.each(*_)
            values.each { |i| yield i }
          end
        end
      end

      before do
        cache.collection(mapping, :database_record_type)
      end

      it "does not re-invoke the original method call" do
        mapping.stub(:database_record_type, dummy_collection) do
          instances = cache.collection(mapping, :database_record_type)
          expect(instances.first.record).to_equal object
        end
      end

      describe "when the mapping's conditions have been modified" do
        before do
          mapping.conditions = ["Name != null"]
        end

        it "caches the mapping separately, and re-invokes the original method call" do
          mapping.stub(:database_record_type, dummy_collection) do
            instances = cache.collection(mapping, :database_record_type)
            expect(instances).to_equal dummy_collection.values
          end
        end
      end
    end
  end

end
