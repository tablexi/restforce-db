# A small utility class to allow for transactional Salesforce record creation.
class Salesforce

  class << self

    attr_accessor :records

  end

  self.records = []

  # Public: Configure Restforce::DB for purposes of test execution.
  #
  # Returns nothing.
  def self.configure!
    Restforce::DB.configure { |config| config.load(Secrets["client"]) }
  end

  # Public: Create a basic instance of the passed Salesforce model.
  #
  # salesforce_model - The name of the model which should be created.
  # attributes       - A Hash of attributes to assign to the created object.
  #
  # Returns a Salesforce record ID.
  def self.create!(salesforce_model, attributes = nil)
    attributes ||= { "Name" => "Sample object" }
    salesforce_id = Restforce::DB.client.create!(salesforce_model, attributes)
    Salesforce.records << [salesforce_model, salesforce_id]

    salesforce_id
  end

  # Public: Clean up any data which was added to Salesforce during the current
  # test run. For consistency in our tests, we reset the configuration and discard
  # our current client session each time this method is run.
  #
  # Returns nothing.
  def self.clean!
    Salesforce.records.each do |entry|
      Restforce::DB.client.destroy entry[0], entry[1]
    end
    Salesforce.records = []

    Restforce::DB.reset
  end

end
