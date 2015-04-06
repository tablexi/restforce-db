require_relative "../../../../test_helper"

describe Restforce::DB::Instances::Salesforce do

  configure!
  mappings!

  let(:id) { Salesforce.create!(salesforce_model) }
  let(:instance) { mapping.salesforce_record_type.find(id) }

  describe "#update!", :vcr do
    let(:text) { "Some new text" }

    before do
      instance.update!("Example_Field__c" => text)
    end

    it "updates the local record with the passed attributes" do
      expect(instance.record.Example_Field__c).to_equal text
    end

    it "updates the record in Salesforce with the passed attributes" do
      expect(mapping.salesforce_record_type.find(id).record.Example_Field__c).to_equal text
    end
  end

  describe "#copy!", :vcr do
    let(:text) { "Copied text" }
    let(:copy_from) { Struct.new(:attributes).new(example: text) }

    before do
      instance.copy!(copy_from)
    end

    it "updates the record with the attributes from the copied object" do
      expect(instance.record.Example_Field__c).to_equal text
    end
  end

  describe "#last_update" do
    let(:timestamp) { "2015-03-18T20:28:24.000+0000" }
    let(:record) { Struct.new(:SystemModstamp).new(timestamp) }
    let(:instance) { Restforce::DB::Instances::Salesforce.new(salesforce_model, record) }

    it "parses a time from the record's system modification timestamp" do
      expect(instance.last_update).to_equal(Time.new(2015, 3, 18, 20, 28, 24, 0))
    end
  end

  describe "#synced?", :vcr do

    describe "when no matching database record exists" do

      it "returns false" do
        expect(instance).to_not_be :synced?
      end
    end

    describe "when a matching database record exists" do
      before do
        database_model.create!(salesforce_id: id)
      end

      it "returns true" do
        expect(instance).to_be :synced?
      end
    end
  end

end
