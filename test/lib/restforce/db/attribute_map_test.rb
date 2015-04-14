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
  let(:conversions) { {} }
  let(:boolean_adapter) do
    Object.new.tap do |object|
      def object.to_database(value)
        value == "Yes"
      end

      def object.to_salesforce(value)
        value ? "Yes" : "No"
      end
    end
  end

  let(:attribute_map) { Restforce::DB::AttributeMap.new(database_model, salesforce_model, fields, conversions) }

  describe "#attributes" do
    let(:mapping) do
      Restforce::DB::Mapping.new(database_model, salesforce_model).tap do |m|
        m.fields = fields
      end
    end

    it "builds a normalized Hash of database attribute values" do
      attributes = attribute_map.attributes(database_model) do |attribute|
        expect(mapping.database_fields.include?(attribute)).to_equal true
        attribute
      end

      expect(attributes.keys).to_equal(mapping.database_fields)
      expect(attributes.values).to_equal(mapping.database_fields)
    end

    it "builds a normalized Hash of Salesforce field values" do
      attributes = attribute_map.attributes(salesforce_model) do |attribute|
        expect(mapping.salesforce_fields.include?(attribute)).to_equal true
        attribute
      end

      expect(attributes.keys).to_equal(mapping.database_fields)
      expect(attributes.values).to_equal(mapping.salesforce_fields)
    end

    describe "when an adapter has been defined for an attribute" do
      let(:conversions) { { column_one: boolean_adapter } }

      it "uses the adapter to convert the value returned by the block" do
        attributes = attribute_map.attributes(salesforce_model) { |_| "Yes" }
        expect(attributes).to_equal(
          column_one: true,
          column_two: "Yes",
        )
      end
    end
  end

  describe "#convert" do
    let(:attributes) { { column_one: "some value" } }

    it "converts an attribute Hash to a Salesforce-compatible form" do
      expect(attribute_map.convert(salesforce_model, attributes)).to_equal(
        fields[attributes.keys.first] => attributes.values.first,
      )
    end

    it "performs no special conversion for database columns" do
      expect(attribute_map.convert(database_model, attributes)).to_equal(attributes)
    end

    describe "when one of the attributes is a Date or Time" do
      let(:timestamp) { Time.now }
      let(:attributes) { { column_one: timestamp } }

      it "converts the attribute to an ISO-8601 string for Salesforce" do
        expect(attribute_map.convert(salesforce_model, attributes)).to_equal(
          fields[attributes.keys.first] => timestamp.iso8601,
        )
      end
    end

    describe "when an adapter has been defined for an attribute" do
      let(:conversions) { { column_one: boolean_adapter } }

      it "uses the adapter to convert that attribute to a Salesforce-compatible form" do
        expect(attribute_map.convert(salesforce_model, column_one: true)).to_equal(
          "SF_Field_One__c" => "Yes",
        )
        expect(attribute_map.convert(salesforce_model, column_one: false)).to_equal(
          "SF_Field_One__c" => "No",
        )
      end
    end
  end

  describe "#convert_from_salesforce" do
    let(:attributes) { { "SF_Field_One__c" => "some value" } }

    it "converts an attribute Hash to a database-compatible form" do
      expect(attribute_map.convert_from_salesforce(database_model, attributes)).to_equal(
        fields.key(attributes.keys.first) => attributes.values.first,
      )
    end

    it "performs no special conversion for Salesforce fields" do
      expect(attribute_map.convert_from_salesforce(salesforce_model, attributes)).to_equal(attributes)
    end

    describe "when an adapter has been defined for an attribute" do
      let(:conversions) { { column_one: boolean_adapter } }

      it "uses the adapter to convert that attribute to a database-compatible form" do
        expect(attribute_map.convert_from_salesforce(database_model, "SF_Field_One__c" => "Yes")).to_equal(
          column_one: true,
        )
        expect(attribute_map.convert_from_salesforce(database_model, "SF_Field_One__c" => "No")).to_equal(
          column_one: false,
        )
      end
    end
  end

end
