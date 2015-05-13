module Restforce

  module DB

    # Restforce::DB::Mapping captures a set of mappings between database columns
    # and Salesforce fields, providing utilities to transform hashes of
    # attributes from one to the other.
    class Mapping

      class InvalidMappingError < StandardError; end

      extend Forwardable
      def_delegators(
        :attribute_map,
        :attributes,
        :convert,
        :convert_from_salesforce,
      )

      attr_reader(
        :database_model,
        :salesforce_model,
        :database_record_type,
        :salesforce_record_type,
      )

      attr_accessor(
        :adapter,
        :fields,
        :associations,
        :conditions,
        :strategy,
      )

      # Public: Initialize a new Restforce::DB::Mapping.
      #
      # database_model   - A Class compatible with ActiveRecord::Base.
      # salesforce_model - A String name of an object type in Salesforce.
      # strategy         - A synchronization Strategy object.
      def initialize(database_model, salesforce_model, strategy = Strategies::Always.new)
        @database_model = database_model
        @salesforce_model = salesforce_model

        @database_record_type = RecordTypes::ActiveRecord.new(database_model, self)
        @salesforce_record_type = RecordTypes::Salesforce.new(salesforce_model, self)

        self.adapter = Adapter.new
        self.fields = {}
        self.associations = []
        self.conditions = []
        self.strategy = strategy
      end

      # Public: Get a list of the relevant Salesforce field names for this
      # mapping.
      #
      # Returns an Array.
      def salesforce_fields
        fields.values + associations.map(&:fields).flatten
      end

      # Public: Get a list of the relevant database column names for this
      # mapping.
      #
      # Returns an Array.
      def database_fields
        fields.keys
      end

      # Public: Get the name of the database column which should be used to
      # store the Salesforce lookup ID.
      #
      # Raises an InvalidMappingError if no database column exists.
      # Returns a Symbol.
      def lookup_column
        @lookup_column ||= begin
          column_prefix = salesforce_model.underscore.chomp("__c")
          column = :"#{column_prefix}_salesforce_id"

          if database_record_type.column?(column)
            column
          elsif database_record_type.column?(:salesforce_id)
            :salesforce_id
          else
            raise InvalidMappingError, "#{database_model} must define a Salesforce ID column"
          end
        end
      end

      # Public: Access the Mapping object without any conditions on the fetched
      # records. Allows for a comparison of all modified records to only those
      # modified records that still fit the `where` criteria.
      #
      # block - A block of code to execute in a condition-less context.
      #
      # Yields the Mapping with its conditions removed.
      # Returns the result of the block.
      def unscoped
        criteria = @conditions
        @conditions = []
        yield self
      ensure
        @conditions = criteria
      end

      private

      # Internal: Get an AttributeMap for the fields defined for this mapping.
      #
      # Returns a Restforce::DB::AttributeMap.
      def attribute_map
        @attribute_map ||= AttributeMap.new(database_model, salesforce_model, fields, adapter)
      end

    end

  end

end
