
# Public: Configure Restforce::DB for purposes of test execution. For
# consistency in our tests, we reset the configuration and discard our current
# client session each time this method is run.
#
# Returns nothing.
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

# Public: Create a basic instance of the passed Salesforce model.
#
# salesforce_model - The name of the model which should be created.
# attributes       - A Hash of attributes to assign to the created object.
#
# Returns a Salesforce record ID.
def create!(salesforce_model, attributes = nil)
  attributes ||= { "Name" => "Sample object" }
  Restforce::DB.client.create(salesforce_model, attributes)
end
