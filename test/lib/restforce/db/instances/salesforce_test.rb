require_relative "../../../../test_helper"

describe Restforce::DB::Instances::Salesforce do
  let(:model) do
    Restforce::DB::Models::Salesforce.new(
      "CustomObject__c",
      "Example_Field__c" => :example,
    )
  end
  let(:id) { create!("CustomObject__c") }
  let(:instance) { model.find(id) }

  before { login! }

  describe "#update!", :vcr do
    let(:text) { "Some new text" }

    before do
      instance.update!("Example_Field__c" => text)
    end

    it "updates the local record with the passed attributes" do
      instance.record.Example_Field__c.must_equal text
    end

    it "updates the record in Salesforce with the passed attributes" do
      model.find(id).record.Example_Field__c.must_equal text
    end
  end

  describe "#copy!", :vcr do
    let(:text) { "Copied text" }
    let(:copy_from) { Struct.new(:attributes).new(example: text) }

    before do
      instance.copy!(copy_from)
    end

    it "updates the record with the attributes from the copied object" do
      instance.record.Example_Field__c.must_equal text
    end
  end
end
