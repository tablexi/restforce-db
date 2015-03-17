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
    Restforce::DB.configuration.username.must_equal Secrets["client"]["username"]
    Restforce::DB.configuration.password.must_equal Secrets["client"]["password"]
    Restforce::DB.configuration.security_token.must_equal Secrets["client"]["security_token"]
    Restforce::DB.configuration.client_id.must_equal Secrets["client"]["client_id"]
    Restforce::DB.configuration.client_secret.must_equal Secrets["client"]["client_secret"]
    Restforce::DB.configuration.host.must_equal Secrets["client"]["host"]
  end
end
