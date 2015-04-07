require_relative "../../../test_helper"

describe Restforce::DB::Initializer do

  configure!
  mappings!

  let(:initializer) { Restforce::DB::Initializer.new(mapping) }

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
          initializer.run
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
          initializer.run
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
      end

      describe "for a root mapping" do
        before do
          initializer.run
          Salesforce.records << [salesforce_model, salesforce_id]
        end

        it "populates Salesforce with the new record" do
          record = mapping.salesforce_record_type.find(salesforce_id).record

          expect(record.Name).to_equal attributes[:name]
          expect(record.Example_Field__c).to_equal attributes[:example]
        end
      end

      describe "for a non-root mapping" do
        let(:through) { "SomeField__c" }

        before do
          initializer.run
        end

        it "does not create a Salesforce record" do
          expect(salesforce_id).to_be_nil
        end
      end
    end

  end
end
