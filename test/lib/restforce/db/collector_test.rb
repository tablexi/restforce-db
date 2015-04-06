require_relative "../../../test_helper"

describe Restforce::DB::Collector do

  configure!
  mappings!

  let(:collector) { Restforce::DB::Collector.new(mapping) }

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
    subject { collector.run }

    describe "given an existing Salesforce record" do
      before { salesforce_id }

      it "returns the attributes from the Salesforce record" do
        record = mapping.salesforce_record_type.find(salesforce_id)

        expect(subject[salesforce_id]).to_equal(
          record.last_update => {
            "Name" => attributes[:name],
            "Example_Field__c" => attributes[:example],
          },
        )
      end
    end

    describe "given an existing database record" do
      let(:salesforce_id) { "a001a000001E1vREAL" }
      let(:database_metadata) { { salesforce_id: salesforce_id, synchronized_at: Time.now } }
      let(:database_record) { database_model.create!(attributes.merge(database_metadata)) }

      before { database_record }

      it "returns the attributes from the database record" do
        record = mapping.database_record_type.find(salesforce_id)

        expect(subject[salesforce_id]).to_equal(
          record.last_update => {
            "Name" => attributes[:name],
            "Example_Field__c" => attributes[:example],
          },
        )
      end
    end

    describe "given a Salesforce record with an associated database record" do
      let(:database_attributes) do
        {
          name:    "Some existing name",
          example: "Some existing sample text",
        }
      end
      let(:database_metadata) { { salesforce_id: salesforce_id, synchronized_at: Time.now } }
      let(:database_record) { database_model.create!(database_attributes.merge(database_metadata)) }

      before { database_record }

      it "returns the attributes from both records" do
        sf_record = mapping.salesforce_record_type.find(salesforce_id)
        db_record = mapping.database_record_type.find(salesforce_id)

        expect(subject[salesforce_id]).to_equal(
          sf_record.last_update => {
            "Name" => attributes[:name],
            "Example_Field__c" => attributes[:example],
          },
          db_record.last_update => {
            "Name" => database_attributes[:name],
            "Example_Field__c" => database_attributes[:example],
          },
        )
      end
    end

  end
end
