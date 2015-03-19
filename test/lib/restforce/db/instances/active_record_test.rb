require_relative "../../../../test_helper"

describe Restforce::DB::Instances::ActiveRecord do

  configure!

  let(:record) { CustomObject.create! }
  let(:mapping) { Restforce::DB::Mapping.new(example: "Example_Field__c") }
  let(:instance) { Restforce::DB::Instances::ActiveRecord.new(record, mapping) }

  describe "#update!" do
    let(:text) { "Some new text" }

    before do
      instance.update!(example: text)
    end

    it "updates the local record with the passed attributes" do
      expect(record.example).to_equal text
    end

    it "updates the record in Salesforce with the passed attributes" do
      expect(record.reload.example).to_equal text
    end
  end

  describe "#copy!" do
    let(:text) { "Copied text" }
    let(:copy_from) { Struct.new(:attributes).new(example: text) }

    before do
      instance.copy!(copy_from)
    end

    it "updates the record with the attributes from the copied object" do
      expect(record.example).to_equal text
    end
  end
end
