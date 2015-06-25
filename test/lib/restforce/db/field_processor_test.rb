require_relative "../../../test_helper"

describe Restforce::DB::FieldProcessor do

  configure!

  let(:processor) { Restforce::DB::FieldProcessor.new }
  let(:dummy_client) do
    Object.new.tap do |client|

      def client.describe(_)
        raise "This has already been invoked!" if @already_run
        @already_run = true

        Struct.new(:fields).new([
          { "name" => "Createable", "createable" => true, "updateable" => false },
          { "name" => "Updateable", "createable" => false, "updateable" => true },
          { "name" => "Both", "createable" => true, "updateable" => true },
          { "name" => "Neither", "createable" => false, "updateable" => false },
        ])
      end

    end
  end

  describe "#available_fields" do
    let(:fields) do
      %w(
        Createable
        Updateable
        Both
        Neither
        Relationship__r.Relateable
      )
    end

    it "filters the passed fields to only existing fields for an object" do
      Restforce::DB.stub(:client, dummy_client) do
        excessive_fields = fields + ["NonExistent"]
        expect(processor.available_fields("CustomObject__c", excessive_fields)).to_equal(fields)
      end
    end

    it "filters the passed fields to only createable fields" do
      Restforce::DB.stub(:client, dummy_client) do
        expect(processor.available_fields("CustomObject__c", fields, :create)).to_equal(%w(
          Createable
          Both
        ))
      end
    end

    it "filters the passed fields to only updateable fields" do
      Restforce::DB.stub(:client, dummy_client) do
        expect(processor.available_fields("CustomObject__c", fields, :update)).to_equal(%w(
          Updateable
          Both
        ))
      end
    end
  end

  describe "#process" do
    let(:attributes) do
      {
        "Createable" => "This field is create-only!",
        "Updateable" => "And... this field is update-only!",
        "Both"       => "But... this field allows both!",
        "Neither"    => "Unfortunately, this field allows neither.",
      }
    end

    it "removes the non-creatable fields from the passed attribute Hash on :create" do
      Restforce::DB.stub(:client, dummy_client) do
        expect(processor.process("CustomObject__c", attributes, :create)).to_equal(
          "Createable" => attributes["Createable"],
          "Both"       => attributes["Both"],
        )
      end
    end

    it "removes the non-updateable fields from the passed attribute Hash on :update" do
      Restforce::DB.stub(:client, dummy_client) do
        expect(processor.process("CustomObject__c", attributes, :update)).to_equal(
          "Updateable" => attributes["Updateable"],
          "Both"       => attributes["Both"],
        )
      end
    end

    it "invokes the client only once for a single SObject Type" do
      Restforce::DB.stub(:client, dummy_client) do
        processor.process("CustomObject__c", attributes, :update)

        # Our dummy client is configured to raise an error if `#describe` is
        # invoked more than once. There is no "wont_raise" in Minitest.
        processor.process("CustomObject__c", attributes, :create)
      end
    end
  end

end
