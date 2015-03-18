require_relative "../../../../test_helper"

describe Restforce::DB::Instances::Salesforce do
  let(:mapping) { Restforce::DB::Mapping.new(example: "Example_Field__c") }
  let(:model) { Restforce::DB::RecordTypes::Salesforce.new("CustomObject__c", mapping) }
  let(:id) { create!("CustomObject__c") }
  let(:instance) { model.find(id) }

  before { login! }
  after  { clean! }

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
end
