require_relative "../../../../test_helper"

describe Restforce::DB::Associations::HasMany do

  configure!
  mappings!

  let(:association) { Restforce::DB::Associations::HasMany.new(:details, through: "CustomObject__c") }

  it "sets the lookup field" do
    expect(association.lookup).to_equal "CustomObject__c"
  end

  describe "#fields" do

    it "returns nothing (since the lookup field is external)" do
      expect(association.fields).to_equal []
    end
  end

  describe "#build", :vcr do
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
    let(:detail_salesforce_ids) do
      [
        Salesforce.create!(
          inverse_mapping.salesforce_model,
          "Name" => "First Detail",
          "CustomObject__c" => object_salesforce_id,
        ),
        Salesforce.create!(
          inverse_mapping.salesforce_model,
          "Name" => "Second Detail",
          "CustomObject__c" => object_salesforce_id,
        ),
        Salesforce.create!(
          inverse_mapping.salesforce_model,
          "Name" => "Third Detail",
          "CustomObject__c" => object_salesforce_id,
        ),
      ]
    end
    let(:database_record) { CustomObject.new }
    let(:salesforce_record) { mapping.salesforce_record_type.find(object_salesforce_id).record }
    let(:associated) { association.build(database_record, salesforce_record) }

    before do
      Restforce::DB::Registry << mapping
      Restforce::DB::Registry << inverse_mapping
      mapping.associations << association
    end

    it "builds a number of associated records from the data in Salesforce" do
      detail_salesforce_ids.each do |id|
        record = associated.detect { |a| a.salesforce_id == id }

        expect(record).to_not_be_nil
        expect(record.custom_object).to_equal database_record
      end
    end
  end
end
