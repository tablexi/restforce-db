require_relative "../../../../test_helper"

describe Restforce::DB::Associations::HasOne do

  configure!
  mappings!

  let(:association) { Restforce::DB::Associations::HasOne.new(:custom_object, through: "Friend__c") }
  let(:inverse_association) { Restforce::DB::Associations::BelongsTo.new(:user, through: %w(Id Friend__c)) }

  it "sets the lookup field" do
    expect(association.lookup).to_equal "Friend__c"
  end

  describe "#fields" do

    it "returns nothing (since the lookup field is external)" do
      expect(association.fields).to_equal []
    end
  end

  describe "with an inverse mapping", :vcr do
    let(:inverse_mapping) do
      Restforce::DB::Mapping.new(User, "Contact").tap do |map|
        map.fields = { email: "Email" }
        map.associations << association
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

    before do
      Restforce::DB::Registry << mapping
      Restforce::DB::Registry << inverse_mapping
      mapping.associations << inverse_association

      object_salesforce_id
    end

    describe "#synced_for?" do
      let(:salesforce_instance) { inverse_mapping.salesforce_record_type.find(user_salesforce_id) }

      describe "when no matching associated record has been synchronized" do

        it "returns false" do
          expect(association).to_not_be :synced_for?, salesforce_instance
        end
      end

      describe "when a matching associated record has been synchronized" do
        before do
          mapping.database_model.create!(salesforce_id: object_salesforce_id)
        end

        it "returns true" do
          expect(association).to_be :synced_for?, salesforce_instance
        end
      end
    end

    describe "#build" do
      let(:database_record) { User.new }
      let(:salesforce_record) { inverse_mapping.salesforce_record_type.find(user_salesforce_id).record }
      let(:associated) { association.build(database_record, salesforce_record) }

      it "returns an associated record, populated with the Salesforce attributes" do
        object = associated.first
        expect(object.user).to_equal database_record
        expect(object.salesforce_id).to_equal object_salesforce_id
      end

      describe "when the association is non-building" do
        let(:association) { Restforce::DB::Associations::HasOne.new(:custom_object, through: "Friend__c", build: false) }

        it "proceeds without constructing any records" do
          expect(associated).to_be :empty?
        end
      end

      describe "when no salesforce record is found for the association" do
        let(:object_salesforce_id) { nil }

        it "proceeds without constructing any records" do
          expect(associated).to_be :empty?
        end
      end

      describe "when the associated record has already been persisted" do
        let(:object) { CustomObject.create!(salesforce_id: object_salesforce_id) }

        before { object }

        it "assigns the existing record" do
          expect(associated).to_be :empty?
          expect(database_record.custom_object).to_equal object
        end
      end

      describe "when the associated record has been cached" do
        let(:object) { CustomObject.new(salesforce_id: object_salesforce_id) }
        let(:cache) { Restforce::DB::AssociationCache.new }
        let(:associated) { association.build(database_record, salesforce_record, cache) }

        before { cache << object }

        it "uses the cached record" do
          expect(associated).to_be :empty?
          expect(database_record.custom_object).to_equal object
        end
      end

      describe "and a nested association on the associated mapping" do
        let(:nested_mapping) do
          Restforce::DB::Mapping.new(Detail, "CustomObjectDetail__c").tap do |map|
            map.fields = { name: "Name" }
            map.associations << Restforce::DB::Associations::BelongsTo.new(
              :custom_object,
              through: "CustomObject__c",
            )
          end
        end
        let(:nested_association) do
          Restforce::DB::Associations::HasMany.new(:details, through: "CustomObject__c")
        end
        let(:detail_salesforce_id) do
          Salesforce.create!(
            nested_mapping.salesforce_model,
            "CustomObject__c" => object_salesforce_id,
          )
        end

        before do
          Restforce::DB::Registry << nested_mapping
          mapping.associations << nested_association
        end

        it "recursively builds all associations" do
          detail_salesforce_id
          expect(associated.length).to_equal 2

          object, detail = associated

          expect(object).to_be_instance_of CustomObject
          expect(object.user).to_equal database_record

          expect(detail).to_be_instance_of Detail
          expect(detail.custom_object).to_equal object
        end
      end
    end
  end

end
