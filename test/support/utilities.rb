# :nodoc:
def configure!
  before do
    Salesforce.configure!
  end

  after do
    Restforce::DB::Registry.clean!
    Restforce::DB.last_run = nil

    DatabaseCleaner.clean
    Salesforce.clean!
  end
end

# :nodoc:
def mappings!
  let(:database_model) { CustomObject }
  let(:salesforce_model) { "CustomObject__c" }
  let(:fields) { { name: "Name", example: "Example_Field__c" } }
  let(:conditions) { [] }
  let(:mapping) do
    Restforce::DB::Mapping.new(database_model, salesforce_model).tap do |m|
      m.conditions = conditions
      m.fields     = fields
    end
  end
end

# :nodoc:
def boolean_adapter
  Object.new.tap do |object|

    def object.to_database(value)
      value == "Yes"
    end

    def object.to_salesforce(value)
      value ? "Yes" : "No"
    end

  end
end
