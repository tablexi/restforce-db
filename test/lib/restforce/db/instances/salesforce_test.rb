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
  let(:text) { "Some new text" }

  before { login! }

  describe "#update!", :vcr do
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
end
