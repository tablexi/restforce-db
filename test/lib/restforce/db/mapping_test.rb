require_relative "../../../test_helper"

describe Restforce::DB::Mapping do

  configure!

  let(:database_model) { CustomObject }
  let(:salesforce_model) { "CustomObject__c" }
  let(:associations) { {} }
  let(:fields) do
    {
      column_one: "SF_Field_One__c",
      column_two: "SF_Field_Two__c",
    }
  end
  let!(:mapping) do
    Restforce::DB::Mapping.new(
      database_model,
      salesforce_model,
      fields: fields,
      associations: associations,
    )
  end

  describe ".each" do

    # Restforce::DB::Mapping actually implements Enumerable, so we're just
    # going with a trivially testable portion of the Enumerable API.
    it "yields the registered record types" do
      expect(Restforce::DB::Mapping.first).to_equal [database_model.name, mapping]
    end
  end

  describe "#initialize" do

    it "adds the mapping to the global collection" do
      expect(Restforce::DB::Mapping[database_model]).to_equal mapping
    end
  end

  describe "#salesforce_fields" do

    describe "given no mapped associations" do

      it "lists the fields in the attribute map" do
        expect(mapping.salesforce_fields).to_equal(fields.values)
      end
    end

    describe "given a set of associations" do
      let(:associations) { { user: "Owner" } }

      it "lists the field and association lookups" do
        expect(mapping.salesforce_fields).to_equal(fields.values + associations.values)
      end
    end
  end

  describe "#lookup_column" do
    let(:db) { mapping.database_record_type }

    describe "when the database table has a column matching the Salesforce model" do
      before do
        def db.column?(_)
          true
        end
      end

      it "returns the explicit column name" do
        expect(mapping.lookup_column).to_equal(:custom_object_salesforce_id)
      end
    end

    describe "when the database table has a generic salesforce ID column" do
      before do
        def db.column?(column)
          column == :salesforce_id
        end
      end

      it "returns the generic column name" do
        expect(mapping.lookup_column).to_equal(:salesforce_id)
      end
    end

    describe "when the database table has no salesforce ID column" do
      before do
        def db.column?(_)
          false
        end
      end

      it "raises an error" do
        expect(-> { mapping.lookup_column }).to_raise Restforce::DB::Mapping::InvalidMappingError
      end
    end
  end

  describe "#attributes" do

    it "builds a normalized Hash of database attribute values" do
      attributes = mapping.attributes(database_model) do |attribute|
        expect(mapping.database_fields.include?(attribute)).to_equal true
        attribute
      end

      expect(attributes.keys).to_equal(mapping.database_fields)
      expect(attributes.values).to_equal(mapping.database_fields)
    end

    it "builds a normalized Hash of Salesforce field values" do
      attributes = mapping.attributes(salesforce_model) do |attribute|
        expect(mapping.salesforce_fields.include?(attribute)).to_equal true
        attribute
      end

      expect(attributes.keys).to_equal(mapping.database_fields)
      expect(attributes.values).to_equal(mapping.salesforce_fields)
    end
  end

  describe "#convert" do
    let(:attributes) { { column_one: "some value" } }

    it "converts an attribute Hash to a Salesforce-compatible form" do
      expect(mapping.convert(salesforce_model, attributes)).to_equal(
        fields[attributes.keys.first] => attributes.values.first,
      )
    end

    it "performs no special conversion for database columns" do
      expect(mapping.convert(database_model, attributes)).to_equal(attributes)
    end
  end
end
