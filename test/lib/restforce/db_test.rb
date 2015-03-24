require_relative "../../test_helper"

describe Restforce::DB do

  configure!

  describe "#configure" do

    it "yields a Configuration" do
      Restforce::DB.configure do |config|
        expect(config).to_be_instance_of(Restforce::DB::Configuration)
      end
    end
  end

  describe "accessing Salesforce", :vcr do

    it "uses the configured credentials" do
      expect(Restforce::DB.client.authenticate!.access_token).to_not_be_nil
    end

  end

end
