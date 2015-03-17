module Restforce

  module DB

    # Public: Restforce::DB::Model is an abstraction for a two-way binding
    # between an ActiveRecord class and a Salesforce object type. It provides an
    # interface for mapping database columns to Salesforce fields.
    class Model

      # Public: Initialize a Restforce::DB::Model.
      #
      # db_model         - A Class compatible with ActiveRecord::Base.
      # salesforce_model - A String name of an object type in Salesforce.
      def initialize(db_model, salesforce_model, **mappings)
        @database_model = Models::ActiveRecord.new(db_model, mappings.dup)
        @salesforce_model = Models::Salesforce.new(salesforce_model, mappings.invert)
      end

      # Public: Append the passed mappings to this model.
      #
      # mappings - A Hash of database column names mapped to Salesforce fields.
      #
      # Returns nothing.
      def map(mappings)
        @database_model.map mappings.dup
        @salesforce_model.map mappings.invert
      end

    end

  end

end
