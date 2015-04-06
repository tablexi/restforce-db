require_relative "../../../test_helper"

describe Restforce::DB::Synchronizer do

  configure!
  mappings!

  let(:synchronizer) { Restforce::DB::Synchronizer.new(mapping) }

  describe "#run", vcr: { match_requests_on: [:method, VCR.request_matchers.uri_without_param(:q)] } do
    let(:attributes) do
      {
        name:    "Custom object",
        example: "Some sample text",
      }
    end
    let(:salesforce_id) do
      Salesforce.create!(
        salesforce_model,
        mapping.convert(salesforce_model, attributes),
      )
    end

    describe "given an existing Salesforce record" do
      before do
        salesforce_id
      end

      describe "for a root mapping" do
        before do
          synchronizer.run
        end

        it "creates a matching database record" do
          record = database_model.last

          expect(record.name).to_equal attributes[:name]
          expect(record.example).to_equal attributes[:example]
          expect(record.salesforce_id).to_equal salesforce_id
        end
      end

      describe "for a non-root mapping" do
        let(:through) { "SomeField__c" }

        before do
          synchronizer.run
        end

        it "does not create a database record" do
          expect(database_model.last).to_be_nil
        end
      end
    end

    describe "given an existing database record" do
      let(:database_record) { database_model.create!(attributes) }
      let(:salesforce_id) { database_record.reload.salesforce_id }

      before do
        database_record
        synchronizer.run

        Salesforce.records << [salesforce_model, salesforce_id]
      end

      it "populates Salesforce with the new record" do
        record = mapping.salesforce_record_type.find(salesforce_id).record

        expect(record.Name).to_equal attributes[:name]
        expect(record.Example_Field__c).to_equal attributes[:example]
      end
    end

    describe "given a Salesforce record with an associated database record" do
      let!(:database_attributes) do
        {
          name:            "Some existing name",
          example:         "Some existing sample text",
          synchronized_at: Time.now,
        }
      end
      let(:database_record) do
        database_model.create!(database_attributes.merge(salesforce_id: salesforce_id))
      end

      describe "when synchronization is stale" do
        before do
          # Set the synchronization timestamp to 5 seconds before the Salesforce
          # modification timestamp.
          updated = mapping.salesforce_record_type.find(salesforce_id).last_update
          database_record.update!(synchronized_at: updated - 5)

          synchronizer.run
        end

        it "updates the database record" do
          record = database_record.reload

          expect(record.name).to_equal attributes[:name]
          expect(record.example).to_equal attributes[:example]
        end
      end

      describe "when synchronization is up-to-date" do
        before do
          database_record.touch(:synchronized_at)
          synchronizer.run
        end

        it "does not update the database record" do
          record = database_record.reload

          expect(record.name).to_equal database_attributes[:name]
          expect(record.example).to_equal database_attributes[:example]
        end
      end
    end

  end
end
