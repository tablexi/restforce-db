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
  let(:through) { nil }
  let!(:mapping) do
    Restforce::DB::Mapping.new(
      database_model,
      salesforce_model,
      fields: fields,
      associations: associations,
      through: through,
    )
  end

  describe ".each" do

    # Restforce::DB::Mapping actually implements Enumerable, so we're just
    # going with a trivially testable portion of the Enumerable API.
    it "yields the registered record types" do
      expect(Restforce::DB::Mapping.first).to_equal mapping
    end
  end

  describe "#initialize" do

    it "adds the mapping to the global collection" do
      expect(Restforce::DB::Mapping[database_model]).to_equal [mapping]
      expect(Restforce::DB::Mapping[salesforce_model]).to_equal [mapping]
    end

    it "defaults to an initialization strategy of `Always`" do
      expect(mapping.strategy).to_be_instance_of(Restforce::DB::Strategies::Always)
    end

    describe "when a :through option is supplied" do
      let(:through) { "Some_Field__c" }

      it "employs a `Passive` initialization strategy" do
        expect(mapping.strategy).to_be_instance_of(Restforce::DB::Strategies::Passive)
      end
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
end
