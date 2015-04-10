require_relative "../../../../test_helper"

describe Restforce::DB::Associations::HasOne do

  configure!
  mappings!

  let(:association) { Restforce::DB::Associations::HasOne.new(:custom_object, through: "Friend__c") }

  it "sets the lookup field" do
    expect(association.lookup).to_equal "Friend__c"
  end

  describe "#fields" do

    it "returns nothing (since the lookup field is external)" do
      expect(association.fields).to_equal []
    end
  end

  describe "#build", :vcr do
    let(:inverse_mapping) do
      Restforce::DB::Mapping.new(User, "Contact").tap do |m|
        m.fields = { email: "Email" }
        m.associations << association
      end
    end
    let(:user_salesforce_id) do
      Salesforce.create!(
        inverse_mapping.salesforce_model,
        "Email" => "somebody@example.com",
        "LastName" => "Somebody",
      )
    end
    let(:object_salesforce_id) do
      Salesforce.create!(mapping.salesforce_model, "Friend__c" => user_salesforce_id)
    end
    let(:database_record) { User.new }
    let(:salesforce_record) { inverse_mapping.salesforce_record_type.find(user_salesforce_id).record }
    let(:associated) { association.build(database_record, salesforce_record) }

    before do
      object_salesforce_id

      Restforce::DB::Registry << mapping
      Restforce::DB::Registry << inverse_mapping
      mapping.associations << Restforce::DB::Associations::BelongsTo.new(:user, through: "Friend__c")
    end

    it "returns an associated record, populated with the Salesforce attributes" do
      expect(associated.user).to_equal database_record
      expect(associated.salesforce_id).to_equal object_salesforce_id
    end
  end
end
