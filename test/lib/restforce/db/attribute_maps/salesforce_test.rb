require_relative "../../../../test_helper"

describe Restforce::DB::AttributeMaps::Salesforce do

  configure!

  let(:attribute_map) { Restforce::DB::AttributeMaps::Salesforce.new(fields) }
  let(:fields) do
    {
      column_one: "SF_Field_One__c",
      column_two: "SF_Field_Two__c",
    }
  end

  describe "#attributes" do

    it "builds a normalized Hash of Salesforce attribute values" do
      record = Hashie::Mash.new("SF_Field_One__c" => "Winkin", "SF_Field_Two__c" => "Blinkin")
      attributes = attribute_map.attributes(record)

      expect(attributes.keys).to_equal(fields.values)
      expect(attributes.values).to_equal(%w(Winkin Blinkin))
    end

    describe "for a mapping requiring Salesforce association traversal" do
      let(:fields) do
        {
          name: "Name",
          friend_name: "Friend__r.Name",
        }
      end

      it "builds a flattened normalized Hash of Salesforce attribute values" do
        record = Hashie::Mash.new(
          "Name" => "Turner",
          "Friend__r" => { "Name" => "Hooch" },
        )
        attributes = attribute_map.attributes(record)

        expect(attributes.keys).to_equal(fields.values)
        expect(attributes.values).to_equal(%w(Turner Hooch))
      end
    end
  end

  describe "#convert" do
    let(:attributes) { { "SF_Field_One__c" => "some value" } }

    it "doesn't perform any special modification of the passed attribute Hash" do
      expect(attribute_map.convert(attributes)).to_equal(attributes)
    end
  end

end
