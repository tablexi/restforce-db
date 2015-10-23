require_relative "../../test_helper"

describe Restforce::DB do

  configure!

  describe ".configure" do

    it "yields a Configuration" do
      Restforce::DB.configure do |config|
        expect(config).to_be_instance_of(Restforce::DB::Configuration)
      end
    end
  end

  describe ".client" do
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

  describe ".hashed_id" do

    it "returns an 18-character Salesforce ID untouched" do
      expect(Restforce::DB.hashed_id("a001a000002zhZfAAI")).to_equal("a001a000002zhZfAAI")
    end

    it "generates a proper hash for a 15-character Salesforce ID" do
      expect(Restforce::DB.hashed_id("aaaaaaaaaaaaaaa")).to_equal("aaaaaaaaaaaaaaaAAA")
      expect(Restforce::DB.hashed_id("AaaAAAaaAAAaaAA")).to_equal("AaaAAAaaAAAaaAAZZZ")
      expect(Restforce::DB.hashed_id("aAaAAaAaAAaAaAA")).to_equal("aAaAAaAaAAaAaAA000")
      expect(Restforce::DB.hashed_id("AAAAAAAAAAAAAAA")).to_equal("AAAAAAAAAAAAAAA555")

      expect(Restforce::DB.hashed_id("0063200001kSU3I")).to_equal("0063200001kSU3IAAW")
    end

    it "raises an ArgumentError if the passed String contains an invalid character count" do
      expect { Restforce::DB.hashed_id("a001a000002zhZfA") }.to_raise(ArgumentError)
    end
  end

  describe "accessing Salesforce", :vcr do

    it "uses the configured credentials" do
      expect(Restforce::DB.client.authenticate!.access_token).to_not_be_nil
    end

  end

end
