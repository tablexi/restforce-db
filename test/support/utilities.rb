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
