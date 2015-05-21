require_relative "../../../test_helper"

describe Restforce::DB::FieldProcessor do

  configure!

  let(:processor) { Restforce::DB::FieldProcessor.new }

  describe "#process" do
    let(:attributes) do
      {
        "Creatable"  => "This field is create-only!",
        "Updateable" => "And... this field is update-only!",
        "Both"       => "But... this field allows both!",
      }
    end
    let(:dummy_client) do
      Object.new.tap do |client|

        def client.describe(_)
          raise "This has already been invoked!" if @already_run
          @already_run = true

          Struct.new(:fields).new([
            { "name" => "Creatable", "createable" => true, "updateable" => false },
            { "name" => "Updateable", "createable" => false, "updateable" => true },
            { "name" => "Both", "createable" => true, "updateable" => true },
          ])
        end

      end
    end

    it "removes the read-only fields from the passed attribute Hash on :create" do
      Restforce::DB.stub(:client, dummy_client) do
        expect(processor.process("CustomObject__c", attributes, :create)).to_equal(
          "Creatable" => attributes["Creatable"],
          "Both"      => attributes["Both"],
        )
      end
    end

    it "removes the read-only fields from the passed attribute Hash on :update" do
      Restforce::DB.stub(:client, dummy_client) do
        expect(processor.process("CustomObject__c", attributes, :update)).to_equal(
          "Updateable" => attributes["Updateable"],
          "Both"       => attributes["Both"],
        )
      end
    end

    it "invokes the client only once for a single SObject Type" do
      Restforce::DB.stub(:client, dummy_client) do
        processor.process("CustomObject__c", attributes)

        # Our dummy client is configured to raise an error if `#describe` is
        # invoked more than once. There is no "wont_raise" in Minitest.
        processor.process("CustomObject__c", attributes)
      end
    end
  end

end
