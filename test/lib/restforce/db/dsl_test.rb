require_relative "../../../test_helper"

describe Restforce::DB::DSL do

  let(:database_model) { CustomObject }
  let(:salesforce_model) { "CustomObject__c" }
  let(:strategy) { :always }
  let(:dsl) { Restforce::DB::DSL.new(database_model, salesforce_model, strategy) }
  let(:mapping) { dsl.mapping }

  before { dsl }

  describe "#initialize" do

    it "registers a mapping for the passed models" do
      expect(Restforce::DB::Registry[database_model]).to_equal [mapping]
      expect(Restforce::DB::Registry[salesforce_model]).to_equal [mapping]
    end

    describe "when a strategy of :always is specified" do
      let(:strategy) { :always }

      it "respects the declared strategy" do
        expect(dsl.mapping.strategy).to_be_instance_of(Restforce::DB::Strategies::Always)
      end
    end

    describe "when a strategy of :passive is specified" do
      let(:strategy) { :passive }

      it "respects the declared strategy" do
        expect(dsl.mapping.strategy).to_be_instance_of(Restforce::DB::Strategies::Passive)
      end
    end
  end

  describe "#where" do
    let(:conditions) { %w(some list of query conditions) }

    before do
      dsl.where(*conditions)
    end

    it "sets a list of conditions for the mapping" do
      expect(mapping.conditions).to_equal conditions
    end
  end

  describe "#belongs_to" do
    before do
      dsl.belongs_to :some_association, through: "Some_Field__c"
    end

    it "adds an association to the created mapping" do
      expect(mapping.associations).to_equal some_association: "Some_Field__c"
    end
  end

  describe "#has_one" do
    before do
      dsl.has_one :other_association, through: "Other_Field__c"
    end

    it "sets the `through` attribute for the created mapping" do
      expect(mapping.through).to_equal "Other_Field__c"
    end
  end

  describe "#maps" do
    let(:fields) { { some: "Fields__c", to: "Sync__c" } }

    before do
      dsl.maps fields
    end

    it "sets the fields for the created mapping" do
      expect(mapping.fields).to_equal fields
    end
  end
end
