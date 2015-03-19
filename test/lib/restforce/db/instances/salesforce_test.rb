require_relative "../../../../test_helper"

describe Restforce::DB::Instances::Salesforce do

  configure!

  let(:mapping) { Restforce::DB::Mapping.new(example: "Example_Field__c") }
  let(:model) { Restforce::DB::RecordTypes::Salesforce.new("CustomObject__c", mapping) }
  let(:id) { Salesforce.create!("CustomObject__c") }
  let(:instance) { model.find(id) }

  describe "#update!", :vcr do
    let(:text) { "Some new text" }

    before do
      instance.update!("Example_Field__c" => text)
    end

    it "updates the local record with the passed attributes" do
      expect(instance.record.Example_Field__c).to_equal text
    end

    it "updates the record in Salesforce with the passed attributes" do
      expect(model.find(id).record.Example_Field__c).to_equal text
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
    let(:instance) { Restforce::DB::Instances::Salesforce.new(record) }

    it "parses a time from the record's system modification timestamp" do
      expect(instance.last_update).to_equal(Time.new(2015, 3, 18, 20, 28, 24, 0))
    end
  end

end
