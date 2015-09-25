require_relative "../../../test_helper"

describe Restforce::DB::Model do

  configure!

  describe "given a database model which includes the module" do
    let(:database_model) { CustomObject }
    let(:salesforce_model) { "CustomObject__c" }

    before do
      database_model.send(:include, Restforce::DB::Model)
    end

    describe ".sync_with" do
      before do
        database_model.sync_with(salesforce_model) do
          maps(
            name:    "Name",
            example: "Example_Field__c",
          )
        end
      end

      it "adds a mapping to the global Restforce::DB::Registry" do
        expect(Restforce::DB::Registry[database_model]).to_not_be :empty?
      end
    end

    describe "#force_sync!", :vcr do
      let(:mapping) { Restforce::DB::Registry[database_model].first }

      before do
        database_model.sync_with(salesforce_model) do
          maps(
            name:    "Name",
            example: "Example_Field__c",
          )
        end
      end

      describe "given an unpersisted record for a mapped model" do
        let(:record) { database_model.new }

        it "does nothing" do
          expect(record.force_sync!).to_equal false
        end
      end

      describe "given an unsynchronized record for a mapped model" do
        let(:record) { database_model.create!(attributes) }
        let(:attributes) do
          {
            name: "Frederick's Flip-flop",
            example: "Yes, we only have the left one.",
          }
        end

        before do
          expect(record.force_sync!).to_equal true
          Salesforce.records << [salesforce_model, record.salesforce_id]
        end

        it "creates a matching record in Salesforce" do
          salesforce_record = mapping.salesforce_record_type.find(
            record.salesforce_id,
          ).record

          expect(salesforce_record.Name).to_equal attributes[:name]
          expect(salesforce_record.Example_Field__c).to_equal attributes[:example]
        end
      end

      describe "given a previously-synchronized record for a mapped model" do
        let(:attributes) do
          {
            name: "Sally's Seashells",
            example: "She sells them down by the seashore.",
          }
        end
        let(:salesforce_id) do
          Salesforce.create!(
            salesforce_model,
            "Name" => attributes[:name],
            "Example_Field__c" => attributes[:example],
          )
        end
        let(:record) { database_model.create!(attributes.merge(salesforce_id: salesforce_id)) }

        it "force-updates both synchronized records" do
          record.update!(name: "Sarah's Seagulls")
          expect(record.force_sync!).to_equal true

          salesforce_record = mapping.salesforce_record_type.find(salesforce_id).record
          expect(salesforce_record.Name).to_equal record.name
        end

        describe "and a mutually exclusive mapping" do
          let(:other_mapping) do
            Restforce::DB::Mapping.new(database_model, salesforce_model).tap do |map|
              map.conditions = [
                "Example_Field__c != '#{attributes[:example]}'",
              ]
            end
          end

          before do
            Restforce::DB::Registry << other_mapping
          end

          it "ignores the problematic mapping" do
            record.update!(name: "Sarah's Seagulls")
            expect(record.force_sync!).to_equal true

            salesforce_record = mapping.salesforce_record_type.find(salesforce_id).record
            expect(salesforce_record.Name).to_equal record.name
          end
        end
      end
    end
  end

end
