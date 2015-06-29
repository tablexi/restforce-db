require_relative "../../../test_helper"

describe Restforce::DB::Attacher do

  configure!
  mappings!

  let(:attacher) { Restforce::DB::Attacher.new(mapping) }

  describe "#run", vcr: { match_requests_on: [:method, VCR.request_matchers.uri_without_param(:q)] } do
    let(:attributes) do
      {
        "SynchronizationId__c" => "CustomObject::#{database_record.id}",
      }
    end
    let(:database_record) { database_model.create! }
    let(:salesforce_id) { Salesforce.create!(salesforce_model, attributes) }

    describe "given a Salesforce record with an upsert ID" do
      before do
        salesforce_id
      end

      describe "for a Passive strategy" do
        before do
          mapping.strategy = Restforce::DB::Strategies::Passive.new
          attacher.run
        end

        it "does nothing" do
          expect(database_record.reload).to_not_be :salesforce_id?
        end
      end

      describe "for an Always strategy" do
        before do
          mapping.strategy = Restforce::DB::Strategies::Always.new
          attacher.run
        end

        it "links the Salesforce record to the matching database record" do
          expect(database_record.reload).to_be :salesforce_id?
        end

        it "wipes the SynchronizationId__c" do
          salesforce_record = mapping.salesforce_record_type.find(salesforce_id).record
          expect(salesforce_record.SynchronizationId__c).to_be_nil
        end

        describe "when the matching database record has a salesforce_id" do
          let(:old_id) { "a001a000001E1vFAKE" }
          let(:database_record) { database_model.create!(salesforce_id: old_id) }

          it "does not change the current Salesforce ID" do
            expect(database_record.reload.salesforce_id).to_equal old_id
          end

          it "wipes the SynchronizationId__c" do
            salesforce_record = mapping.salesforce_record_type.find(salesforce_id).record
            expect(salesforce_record.SynchronizationId__c).to_be_nil
          end
        end

        describe "when no matching database record can be found" do
          let(:database_record) { nil }
          let(:attributes) do
            {
              "SynchronizationId__c" => "CustomObject::1",
            }
          end

          it "wipes the SynchronizationId__c" do
            salesforce_record = mapping.salesforce_record_type.find(salesforce_id).record
            expect(salesforce_record.SynchronizationId__c).to_be_nil
          end
        end

        describe "when the upsert ID is for another database model" do
          let(:attributes) do
            {
              "SynchronizationId__c" => "User::1",
            }
          end

          it "does not wipe the SynchronizationId__c" do
            salesforce_record = mapping.salesforce_record_type.find(salesforce_id).record
            expect(salesforce_record.SynchronizationId__c).to_not_be_nil
          end
        end
      end
    end
  end
end
