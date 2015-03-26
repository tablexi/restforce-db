# :nodoc:
def configure!
  before do
    Salesforce.configure!
  end

  after do
    Restforce::DB::Mapping.collection = {}
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
  let!(:mapping) do
    Restforce::DB::Mapping.new(
      database_model,
      salesforce_model,
      root: true,
      fields: fields,
      associations: associations,
    )
  end
end
