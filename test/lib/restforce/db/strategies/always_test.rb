require_relative "../../../../test_helper"

describe Restforce::DB::Strategies::Always do

  configure!
  mappings!

  let(:strategy) { Restforce::DB::Strategies::Always.new }

  it "is not a passive strategy" do
    expect(strategy).to_not_be :passive?
  end

  describe "#build?", :vcr do

    describe "given a Salesforce record" do
      let(:salesforce_id) { Salesforce.create! "CustomObject__c" }
      let(:record) { mapping.salesforce_record_type.find(salesforce_id) }

      it "wants to build a new matching record" do
        expect(strategy.build?(record)).to_equal true
      end

      describe "with a corresponding database record" do
        before do
          CustomObject.create!(
            salesforce_id: salesforce_id,
            synchronized_at: Time.now,
          )
        end

        it "does not want to build a new record" do
          expect(strategy.build?(record)).to_equal false
        end
      end
    end
  end
end
