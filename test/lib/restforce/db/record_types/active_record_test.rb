require_relative "../../../../test_helper"

describe Restforce::DB::RecordTypes::ActiveRecord do

  configure!
  mappings!

  let(:record_type) { mapping.database_record_type }
  let(:salesforce_id) { "a001a000001E1vREAL" }

  describe "#create!" do
    let(:attributes) do
      {
        "Name"             => "Some name",
        "Example_Field__c" => "Some text",
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
      expect(instance.name).to_equal attributes["Name"]
      expect(instance.example).to_equal attributes["Example_Field__c"]
      expect(instance.synchronized_at).to_not_be_nil
    end

    describe "given a mapped association" do
      let(:record) { Struct.new(:Friend__c).new(association_id) }
      let(:association_id) { "a001a000001EFRIEND" }

      before do
        mapping.associations << Restforce::DB::Associations::BelongsTo.new(
          :user,
          through: "Friend__c",
        )

        associated_mapping = Restforce::DB::Mapping.new(User, "Contact").tap do |map|
          map.fields  = { email: "Email" }
          map.associations << Restforce::DB::Associations::HasOne.new(
            :custom_object,
            through: "Friend__c",
          )
        end
        Restforce::DB::Registry << associated_mapping

        salesforce_record_type = associated_mapping.salesforce_record_type

        # Stub out the `#find` method on the record type
        def salesforce_record_type.find(id)
          Struct.new(:id, :last_update, :mapping, :attributes).new(
            id,
            Time.now,
            Restforce::DB::Registry[User].first,
            "Email" => "somebody@example.com",
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

  describe "#destroy_all" do
    before do
      database_model.create!(salesforce_id: salesforce_id)
      record_type.destroy_all(ids)
    end

    describe "when the passed ids include the Salesforce ID of an existing record" do
      let(:ids) { [salesforce_id] }

      it "eliminates the matching record(s)" do
        expect(database_model.last).to_be_nil
      end
    end

    describe "when the passed ids do not include the Salesforce ID of an existing record" do
      let(:ids) { ["a001a000001E1vFAKE"] }

      it "does not eliminate the matching record(s)" do
        expect(database_model.last).to_not_be_nil
      end
    end
  end
end
