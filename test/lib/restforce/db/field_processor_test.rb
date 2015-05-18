require_relative "../../../test_helper"

describe Restforce::DB::FieldProcessor do

  configure!

  let(:processor) { Restforce::DB::FieldProcessor.new }

  describe "#process" do
    let(:attributes) do
      {
        "Name" => "This field can be updated.",
        "Id"   => "But... but... this field is read-only!",
      }
    end
    let(:dummy_client) do
      Object.new.tap do |client|

        def client.describe(_)
          raise "This has already been invoked!" if @already_run
          @already_run = true

          Struct.new(:fields).new([
            { "name" => "Name", "updateable" => true },
            { "name" => "Id", "updateable" => false },
          ])
        end

      end
    end

    it "removes the read-only fields from the passed attribute Hash" do
      Restforce::DB.stub(:client, dummy_client) do
        expect(processor.process("CustomObject__c", attributes)).to_equal(
          "Name" => attributes["Name"],
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
