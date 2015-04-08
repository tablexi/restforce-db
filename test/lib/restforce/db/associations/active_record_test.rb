require_relative "../../../../test_helper"

describe Restforce::DB::Associations::ActiveRecord do

  configure!
  mappings!

  let(:associations) { { user: "Friend__c" } }
  let(:record) { CustomObject.new }
  let(:association) { Restforce::DB::Associations::ActiveRecord.new(record, :user) }

  describe "#build" do
    let(:association_id) { "a001a000001EFRIEND" }
    let(:salesforce_record) { Hashie::Mash.new("Friend__c" => association_id) }
    let(:associated_record) { association.build(salesforce_record) }

    before do
      mapping = Restforce::DB::Mapping.new(
        User,
        "Contact",
        through: "Friend__c",
        fields: { email: "Email" },
      )
      Restforce::DB::Registry << mapping

      salesforce_record_type = mapping.salesforce_record_type

      # Stub out the `#find` method on the record type
      def salesforce_record_type.find(id)
        Struct.new(:id, :last_update, :attributes).new(
          id,
          Time.now,
          email: "somebody@example.com",
        )
      end
    end

    it "creates the associated record from the related Salesforce record's attributes" do
      expect(associated_record).to_not_be_nil
      expect(associated_record.email).to_equal("somebody@example.com")
      expect(associated_record.salesforce_id).to_equal(association_id)
      expect(associated_record).to_equal record.user
    end
  end
end
