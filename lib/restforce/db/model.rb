module Restforce

  module DB

    class Model

      def initialize(db_model, salesforce_model, **mappings)
        @database_model = Models::ActiveRecord.new(db_model, mappings.dup)
        @salesforce_model = Models::Salesforce.new(salesforce_model, mappings.invert)
      end

      def map(mappings)
        @database_model.map mappings.dup
        @salesforce_model.map mappings.invert
      end

    end

  end

end
