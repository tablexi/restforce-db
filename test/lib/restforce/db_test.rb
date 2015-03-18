require_relative "../../test_helper"

describe Restforce::DB do
  let(:secrets) { Secrets["client"] }

  before do
    Restforce::DB.configure do |config|
      config.username       = secrets["username"]
      config.password       = secrets["password"]
      config.security_token = secrets["security_token"]
      config.client_id      = secrets["client_id"]
      config.client_secret  = secrets["client_secret"]
      config.host           = secrets["host"]
    end
  end

  it "configures the Restforce::DB" do
    expect(Restforce::DB.configuration.username).to_equal secrets["username"]
    expect(Restforce::DB.configuration.password).to_equal secrets["password"]
    expect(Restforce::DB.configuration.security_token).to_equal secrets["security_token"]
    expect(Restforce::DB.configuration.client_id).to_equal secrets["client_id"]
    expect(Restforce::DB.configuration.client_secret).to_equal secrets["client_secret"]
    expect(Restforce::DB.configuration.host).to_equal secrets["host"]
  end

  describe "accessing Salesforce", :vcr do

    after  { clean! }

    it "uses the configured credentials" do
      expect(Restforce::DB.client.authenticate!.access_token).to_not_be_nil
    end

  end

end
