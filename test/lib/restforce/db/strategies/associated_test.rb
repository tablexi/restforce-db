require_relative "../../../../test_helper"

describe Restforce::DB::Strategies::Associated do

  configure!
  mappings!

  let(:strategy) { Restforce::DB::Strategies::Associated.new(with: :custom_object) }

  it "is not a passive strategy" do
    expect(strategy).to_not_be :passive?
  end

  describe "#build?", :vcr do

    describe "given an inverse mapping" do
      let(:inverse_mapping) do
        Restforce::DB::Mapping.new(Detail, "CustomObjectDetail__c").tap do |m|
          m.fields = { name: "Name" }
          m.associations << Restforce::DB::Associations::BelongsTo.new(
            :custom_object,
            through: "CustomObject__c",
          )
        end
      end
      let(:object_salesforce_id) { Salesforce.create!(mapping.salesforce_model) }
      let(:detail_salesforce_id) do
        Salesforce.create!(
          inverse_mapping.salesforce_model,
          "CustomObject__c" => object_salesforce_id,
        )
      end
      let(:record) { inverse_mapping.salesforce_record_type.find(detail_salesforce_id) }

      before do
        Restforce::DB::Registry << mapping
        Restforce::DB::Registry << inverse_mapping
        mapping.associations << Restforce::DB::Associations::HasMany.new(
          :details,
          through: "CustomObject__c",
        )
      end

      describe "with no synchronized association record" do

        it "does not want to build a new record" do
          expect(strategy).to_not_be :build?, record
        end
      end

      describe "with an existing database record" do
        before do
          Detail.create!(
            salesforce_id: detail_salesforce_id,
            synchronized_at: Time.now,
          )
        end

        it "does not want to build a new record" do
          expect(strategy).to_not_be :build?, record
        end
      end

      describe "with a synchronized association record" do
        before do
          CustomObject.create!(
            salesforce_id: object_salesforce_id,
            synchronized_at: Time.now,
          )
        end

        it "wants to build a new record" do
          expect(strategy).to_be :build?, record
        end
      end
    end
  end
end
