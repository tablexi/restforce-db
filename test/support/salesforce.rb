# A small utility class to allow for transactional Salesforce record creation.
class Salesforce

  class << self

    attr_accessor :records

  end

end

Salesforce.records = []

# Public: Configure Restforce::DB for purposes of test execution.
#
# Returns nothing.
def login!
  Restforce::DB.configure do |config|
    config.username       = Secrets["client"]["username"]
    config.password       = Secrets["client"]["password"]
    config.security_token = Secrets["client"]["security_token"]
    config.client_id      = Secrets["client"]["client_id"]
    config.client_secret  = Secrets["client"]["client_secret"]
    config.host           = Secrets["client"]["host"]
  end
end

# Public: Clean up any data which was added to Salesforce during the current
# test run. For consistency in our tests, we reset the configuration and discard
# our current client session each time this method is run.
#
# Returns nothing.
def clean!
  Salesforce.records.each do |(salesforce_model, id)|
    Restforce::DB.client.destroy salesforce_model, id
  end
  Salesforce.records = []

  Restforce::DB.reset
end

# Public: Create a basic instance of the passed Salesforce model.
#
# salesforce_model - The name of the model which should be created.
# attributes       - A Hash of attributes to assign to the created object.
#
# Returns a Salesforce record ID.
def create!(salesforce_model, attributes = nil)
  attributes ||= { "Name" => "Sample object" }
  salesforce_id = Restforce::DB.client.create(salesforce_model, attributes)
  Salesforce.records << [salesforce_model, salesforce_id]

  salesforce_id
end
