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

  describe "#client" do
    before do
      Restforce::DB.configure do |config|
        config.adapter = :net_http
      end
    end

    it "adds the Retry middleware before the adapter" do
      handlers = Restforce::DB.client.middleware.handlers

      expect(handlers[-2].klass).to_equal(Faraday::Request::Retry)
      expect(handlers[-1].klass).to_equal(Faraday::Adapter::NetHttp)
    end
  end

  describe "accessing Salesforce", :vcr do

    it "uses the configured credentials" do
      expect(Restforce::DB.client.authenticate!.access_token).to_not_be_nil
    end

  end

end
