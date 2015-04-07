require_relative "../../../../test_helper"

describe Restforce::DB::Instances::ActiveRecord do

  configure!
  mappings!

  let(:record) { CustomObject.create! }
  let(:instance) do
    Restforce::DB::Instances::ActiveRecord.new(database_model, record, mapping)
  end

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

    it "bumps the record's synchronized_at timestamp" do
      expect(record.reload.synchronized_at).to_not_be_nil
    end
  end
end
