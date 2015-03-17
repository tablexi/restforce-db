require_relative "../../test_helper"

describe Restforce::DB do

  before do
    Restforce::DB.configure do |config|
      config.username       = Secrets["client"]["username"]
      config.password       = Secrets["client"]["password"]
      config.security_token = Secrets["client"]["security_token"]
      config.client_id      = Secrets["client"]["client_id"]
      config.client_secret  = Secrets["client"]["client_secret"]
      config.host           = Secrets["client"]["host"]
    end
  end

  it "configures the Restforce::DB" do
    expect(Restforce::DB.configuration.username).to_equal Secrets["client"]["username"]
    expect(Restforce::DB.configuration.password).to_equal Secrets["client"]["password"]
    expect(Restforce::DB.configuration.security_token).to_equal Secrets["client"]["security_token"]
    expect(Restforce::DB.configuration.client_id).to_equal Secrets["client"]["client_id"]
    expect(Restforce::DB.configuration.client_secret).to_equal Secrets["client"]["client_secret"]
    expect(Restforce::DB.configuration.host).to_equal Secrets["client"]["host"]
  end

  describe "accessing Salesforce", :vcr do

    it "uses the configured credentials" do
      expect(Restforce::DB.client.authenticate!.access_token).to_not_be_nil
    end

  end

end
