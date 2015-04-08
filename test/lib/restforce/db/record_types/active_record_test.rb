require_relative "../../../../test_helper"

describe Restforce::DB::RecordTypes::ActiveRecord do

  configure!
  mappings!

  let(:record_type) { mapping.database_record_type }
  let(:salesforce_id) { "a001a000001E1vREAL" }

  describe "#create!" do
    let(:attributes) do
      {
        name:    "Some name",
        example: "Some text",
      }
    end
    let(:record) { nil }
    let(:create_from) do
      Struct.new(:id, :last_update, :attributes, :record).new(
        salesforce_id,
        Time.now,
        attributes,
        record,
      )
    end
    let(:instance) { record_type.create!(create_from).record }

    before do
      Restforce::DB::Registry << mapping
    end

    it "creates a record in the database from the passed Salesforce record's attributes" do
      expect(instance.salesforce_id).to_equal salesforce_id
      expect(instance.name).to_equal attributes[:name]
      expect(instance.example).to_equal attributes[:example]
      expect(instance.synchronized_at).to_not_be_nil
    end

    describe "given a mapped association" do
      let(:record) { Struct.new(:Friend__c).new(association_id) }
      let(:association_id) { "a001a000001EFRIEND" }
      let(:associations) { { user: "Friend__c" } }

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
        user = instance.reload.user

        expect(user).to_not_be_nil
        expect(user.email).to_equal("somebody@example.com")
        expect(user.salesforce_id).to_equal(association_id)
        expect(user.synchronized_at).to_not_be_nil
        expect(user.synchronized_at).to_be(:>=, user.updated_at)
      end
    end
  end

  describe "#find" do

    it "finds existing records in the database by their salesforce id" do
      database_model.create!(salesforce_id: salesforce_id)
      expect(record_type.find(salesforce_id)).to_be_instance_of Restforce::DB::Instances::ActiveRecord
    end

    it "returns nil when no matching record exists" do
      expect(record_type.find("a001a000001E1vFAKE")).to_be_nil
    end
  end
end
