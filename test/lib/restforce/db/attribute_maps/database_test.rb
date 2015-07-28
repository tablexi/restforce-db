require_relative "../../../../test_helper"

describe Restforce::DB::AttributeMaps::Database do

  configure!

  let(:adapter) { Restforce::DB::Adapter.new }
  let(:attribute_map) { Restforce::DB::AttributeMaps::Database.new(fields, adapter) }
  let(:fields) do
    {
      column_one: "SF_Field_One__c",
      column_two: "SF_Field_Two__c",
    }
  end

  describe "#attributes" do

    it "builds a normalized Hash of database attribute values" do
      record = Hashie::Mash.new(column_one: "Winkin", column_two: "Blinkin")
      attributes = attribute_map.attributes(record)

      expect(attributes.keys).to_equal(fields.values)
      expect(attributes.values).to_equal(%w(Winkin Blinkin))
    end
  end

  describe "#convert" do
    let(:attributes) { { "SF_Field_One__c" => "some value" } }

    it "converts an attribute Hash to a database-compatible form" do
      expect(attribute_map.convert(attributes)).to_equal(
        fields.key(attributes.keys.first) => attributes.values.first,
      )
    end

    describe "when an adapter has been specified" do
      let(:adapter) { boolean_adapter }

      it "uses the adapter to convert attributes to a database-compatible form" do
        expect(attribute_map.convert("SF_Field_One__c" => "Yes")).to_equal(
          column_one: true,
        )
        expect(attribute_map.convert("SF_Field_One__c" => "No")).to_equal(
          column_one: false,
        )
      end

    end
  end

end
