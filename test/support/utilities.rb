# :nodoc:
def configure!
  before do
    Salesforce.configure!
  end

  after do
    Restforce::DB::Registry.clean!
    DatabaseCleaner.clean
    Salesforce.clean!
  end
end

# :nodoc:
def mappings!
  let(:database_model) { CustomObject }
  let(:salesforce_model) { "CustomObject__c" }
  let(:fields) { { name: "Name", example: "Example_Field__c" } }
  let(:associations) { {} }
  let(:conditions) { [] }
  let(:through) { nil }
  let!(:mapping) do
    Restforce::DB::Mapping.new(database_model, salesforce_model).tap do |m|
      m.through      = through
      m.conditions   = conditions
      m.fields       = fields
      m.associations = associations
    end
  end
end
