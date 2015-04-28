require_relative "../../../test_helper"

describe Restforce::DB::Mapping do

  configure!

  let(:database_model) { CustomObject }
  let(:salesforce_model) { "CustomObject__c" }
  let(:fields) do
    {
      column_one: "SF_Field_One__c",
      column_two: "SF_Field_Two__c",
    }
  end
  let(:mapping) do
    Restforce::DB::Mapping.new(database_model, salesforce_model).tap do |m|
      m.fields = fields
    end
  end

  describe "#initialize" do

    it "defaults to an initialization strategy of `Always`" do
      expect(mapping.strategy).to_be_instance_of(Restforce::DB::Strategies::Always)
    end
  end

  describe "#salesforce_fields" do

    describe "given no mapped associations" do

      it "lists the fields in the attribute map" do
        expect(mapping.salesforce_fields).to_equal(fields.values)
      end
    end

    describe "given a set of associations" do
      let(:association) do
        Restforce::DB::Associations::BelongsTo.new(:user, through: "Owner")
      end

      before do
        mapping.associations << association
      end

      it "lists the field and association lookups" do
        expect(mapping.salesforce_fields).to_equal(fields.values + association.fields)
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

  describe "#unscoped" do
    before do
      mapping.conditions = ["Some_Condition__c = TRUE"]
    end

    it "removes the conditions from the mapping within the context of the block" do
      expect(mapping.conditions).to_not_be :empty?
      mapping.unscoped { |m| expect(m.conditions).to_be :empty? }
      expect(mapping.conditions).to_not_be :empty?
    end
  end
end
