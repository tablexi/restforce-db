require_relative "../../../test_helper"

describe Restforce::DB::Associator do

  configure!
  mappings!

  let(:associator) { Restforce::DB::Associator.new(mapping) }

  describe "#run", :vcr do

    describe "given a BelongsTo association" do
      let(:inverse_mapping) do
        Restforce::DB::Mapping.new(User, "Contact").tap do |map|
          map.fields = { email: "Email" }
          map.associations << Restforce::DB::Associations::HasOne.new(
            :custom_object,
            through: "Friend__c",
          )
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
      let(:association) { Restforce::DB::Associations::BelongsTo.new(:user, through: "Friend__c") }
      let(:user) { inverse_mapping.database_model.create!(salesforce_id: user_salesforce_id) }
      let(:object) { mapping.database_model.create!(user: user, salesforce_id: object_salesforce_id) }

      before do
        Restforce::DB::Registry << mapping
        Restforce::DB::Registry << inverse_mapping
        mapping.associations << association
      end

      describe "given another record for association" do
        let(:new_user_salesforce_id) do
          Salesforce.create!(
            inverse_mapping.salesforce_model,
            "Email" => "somebody+else@example.com",
            "LastName" => "Somebody",
          )
        end
        let(:new_user) { inverse_mapping.database_model.create!(salesforce_id: new_user_salesforce_id) }
        let(:salesforce_instance) { mapping.salesforce_record_type.find(object_salesforce_id) }

        describe "when the Salesforce association is out of date" do
          before do
            object.update!(user: new_user)
          end

          it "updates the association ID in Salesforce" do
            associator.run
            expect(salesforce_instance.record["Friend__c"]).to_equal new_user_salesforce_id
          end
        end

        describe "when the database association is out of date" do
          before do
            object && new_user
            salesforce_instance.update! "Friend__c" => new_user_salesforce_id
          end

          it "updates the associated record in the database" do
            # We stub `last_update` to get around issues with VCR's cached
            # timestamp; we need the Salesforce record to be more recent.
            Restforce::DB::Instances::Salesforce.stub_any_instance(:last_update, Time.now) do
              associator.run
            end
            expect(object.reload.user).to_equal new_user
          end
        end
      end
    end
  end
end
