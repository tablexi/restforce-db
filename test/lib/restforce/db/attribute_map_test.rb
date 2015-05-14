require_relative "../../../test_helper"

describe Restforce::DB::AttributeMap do

  configure!

  let(:database_model) { CustomObject }
  let(:salesforce_model) { "CustomObject__c" }
  let(:fields) do
    {
      column_one: "SF_Field_One__c",
      column_two: "SF_Field_Two__c",
    }
  end
  let(:adapter) { Restforce::DB::Adapter.new }
  let(:attribute_map) { Restforce::DB::AttributeMap.new(database_model, salesforce_model, fields, adapter) }

  describe "#attributes" do
    let(:mapping) do
      Restforce::DB::Mapping.new(database_model, salesforce_model).tap do |map|
        map.fields = fields
      end
    end

    it "builds a normalized Hash of database attribute values" do
      attributes = attribute_map.attributes(database_model) do |attribute|
        expect(mapping.database_fields.include?(attribute)).to_equal true
        attribute
      end

      expect(attributes.keys).to_equal(mapping.salesforce_fields)
      expect(attributes.values).to_equal(mapping.database_fields)
    end

    it "builds a normalized Hash of Salesforce field values" do
      attributes = attribute_map.attributes(salesforce_model) do |attribute|
        expect(mapping.salesforce_fields.include?(attribute)).to_equal true
        attribute
      end

      expect(attributes.keys).to_equal(mapping.salesforce_fields)
      expect(attributes.values).to_equal(mapping.salesforce_fields)
    end
  end

  describe "#convert" do
    let(:attributes) { { "SF_Field_One__c" => "some value" } }

    it "converts an attribute Hash to a Salesforce-compatible form" do
      expect(attribute_map.convert(salesforce_model, attributes)).to_equal(attributes)
    end

    it "converts an attribute Hash to a database-compatible form" do
      expect(attribute_map.convert(database_model, attributes)).to_equal(
        fields.key(attributes.keys.first) => attributes.values.first,
      )
    end

    describe "when an adapter has been specified" do
      let(:adapter) { boolean_adapter }

      it "uses the adapter to convert attributes to a database-compatible form" do
        expect(attribute_map.convert(database_model, "SF_Field_One__c" => "Yes")).to_equal(
          column_one: true,
        )
        expect(attribute_map.convert(database_model, "SF_Field_One__c" => "No")).to_equal(
          column_one: false,
        )
      end
    end
  end

end
