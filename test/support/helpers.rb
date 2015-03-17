def login!
  Restforce::DB.reset
  Restforce::DB.configure do |config|
    config.username       = Secrets["client"]["username"]
    config.password       = Secrets["client"]["password"]
    config.security_token = Secrets["client"]["security_token"]
    config.client_id      = Secrets["client"]["client_id"]
    config.client_secret  = Secrets["client"]["client_secret"]
    config.host           = Secrets["client"]["host"]
  end
end

def create!(salesforce_model)
  Restforce::DB.client.create(salesforce_model, "Name" => "Sample object")
end
