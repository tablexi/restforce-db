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
    Restforce::DB::Mapping.new(database_model, salesforce_model).tap do |map|
      map.conditions = conditions
      map.fields     = fields
    end
  end
end

# :nodoc:
def boolean_adapter
  Object.new.tap do |object|

    def object.to_database(attributes)
      attributes.each_with_object({}) do |(k, v), final|
        final[k] = (v == "Yes")
      end
    end

    def object.from_database(attributes)
      attributes.each_with_object({}) do |(k, v), final|
        final[k] = v ? "Yes" : "No"
      end
    end

  end
end
