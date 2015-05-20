require_relative "../../test_helper"

describe Restforce::DB do

  configure!

  describe "#logger" do

    it "defaults to a null logger" do
      log_device = Restforce::DB.logger.instance_variable_get("@logdev")
      expect(log_device.dev.path).to_equal "/dev/null"
    end

    it "allows assignment of a new logger" do
      logger = Logger.new("/dev/null")
      Restforce::DB.logger = logger
      expect(Restforce::DB.logger).to_equal logger
    end
  end

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
