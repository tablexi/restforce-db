module Restforce

  module DB

    # Restforce::DB::Mapping captures a set of mappings between database columns
    # and Salesforce fields, providing utilities to transform hashes of
    # attributes from one to the other.
    class Mapping

      class InvalidMappingError < StandardError; end

      class << self

        include Enumerable
        attr_accessor :collection

        # Public: Get the Restforce::DB::Mapping entry for the specified model.
        #
        # database_model - A String or Class.
        #
        # Returns a Restforce::DB::Mapping.
        def [](model)
          collection[model]
        end

        # Public: Iterate through all registered Restforce::DB::Mappings.
        #
        # Yields one Mapping for each database-to-Salesforce mapping.
        # Returns nothing.
        def each
          collection.each do |model, mappings|
            # Since each mapping is inserted twice, we ignore the half which
            # were inserted via Salesforce model names.
            next unless model.is_a?(Class)

            mappings.each do |mapping|
              yield mapping
            end
          end
        end

        # Public: Add a mapping to the overarching Mapping collection.
        #
        # Returns nothing.
        def <<(mapping)
          [mapping.database_model, mapping.salesforce_model].each do |model|
            collection[model] ||= []
            collection[model] << mapping
          end
        end

      end

      self.collection ||= {}

      extend Forwardable
      def_delegators(
        :@attribute_map,
        :attributes,
        :convert,
        :convert_from_salesforce,
      )

      attr_reader(
        :database_model,
        :salesforce_model,
        :database_record_type,
        :salesforce_record_type,
        :associations,
        :conditions,
        :through,
      )

      # Public: Initialize a new Restforce::DB::Mapping.
      #
      # database_model   - A Class compatible with ActiveRecord::Base.
      # salesforce_model - A String name of an object type in Salesforce.
      # options          - A Hash of mapping attributes. Currently supported
      #                    keys are:
      #                    :fields       - A Hash of mappings between database
      #                                    columns and fields in Salesforce.
      #                    :associations - A Hash of mappings between Active
      #                                    Record association names and the
      #                                    corresponding Salesforce Lookup name.
      #                    :conditions   - An Array of lookup conditions which
      #                                    should be applied to the Salesforce
      #                                    queries.
      #                    :root         - A Boolean reflecting whether or not
      #                                    this is a root-level mapping.
      def initialize(database_model, salesforce_model, options = {})
        @database_model = database_model
        @salesforce_model = salesforce_model

        @database_record_type = RecordTypes::ActiveRecord.new(database_model, self)
        @salesforce_record_type = RecordTypes::Salesforce.new(salesforce_model, self)

        @fields = options.fetch(:fields) { {} }
        @associations = options.fetch(:associations) { {} }
        @conditions = options.fetch(:conditions) { [] }
        @through = options.fetch(:through) { nil }

        @attribute_map = AttributeMap.new(database_model, salesforce_model, @fields)

        self.class << self
      end

      # Public: Get a list of the relevant Salesforce field names for this
      # mapping.
      #
      # Returns an Array.
      def salesforce_fields
        @fields.values + @associations.values.flatten
      end

      # Public: Get a list of the relevant database column names for this
      # mapping.
      #
      # Returns an Array.
      def database_fields
        @fields.keys
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

      # Public: Is this a root-level mapping? Used to determine whether or not
      # to trigger the creation of "missing" database records.
      #
      # Returns a Boolean.
      def root?
        @through.nil?
      end

    end

  end

end
