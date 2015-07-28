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
      record = Hashie::Mash.new(column_one: "Eenie", column_two: "Meenie")
      attributes = attribute_map.attributes(database_model, record)

      expect(attributes.keys).to_equal(mapping.salesforce_fields)
      expect(attributes.values).to_equal(%w(Eenie Meenie))
    end

    it "builds a normalized Hash of Salesforce field values" do
      record = Hashie::Mash.new("SF_Field_One__c" => "Minie", "SF_Field_Two__c" => "Moe")
      attributes = attribute_map.attributes(salesforce_model, record)

      expect(attributes.keys).to_equal(mapping.salesforce_fields)
      expect(attributes.values).to_equal(%w(Minie Moe))
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
  end

end
