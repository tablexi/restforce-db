require_relative "../../../../test_helper"

describe Restforce::DB::Instances::ActiveRecord do

  configure!
  mappings!

  let(:record) { CustomObject.create! }
  let(:instance) do
    Restforce::DB::Instances::ActiveRecord.new(database_model, record, mapping)
  end

  describe "#id" do

    describe "when the record has no synchronized Salesforce ID" do

      it "returns the record's UUID" do
        expect(instance.id).to_equal instance.uuid
      end
    end

    describe "when the record has a synchronized Salesforce ID" do
      let(:salesforce_id) { "a001a000001E1vREAL" }
      before do
        record.update!(salesforce_id: salesforce_id)
      end

      it "returns the Salesforce ID" do
        expect(instance.id).to_equal salesforce_id
      end
    end
  end

  describe "#uuid" do

    it "returns the record's ID" do
      expect(instance.uuid).to_equal "CustomObject::#{record.id}"
    end
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

  describe "#updated_internally?" do

    describe "when updated_at exceeds synchronized_at" do
      before do
        record.update!(synchronized_at: Time.now - 2)
      end

      it "returns false" do
        expect(instance).to_not_be :updated_internally?
      end
    end

    describe "when synchronized_at meets or exceeds updated_at" do
      before do
        record.touch(:synchronized_at)
      end

      it "returns true" do
        expect(instance).to_be :updated_internally?
      end
    end
  end
end
