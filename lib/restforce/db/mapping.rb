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

        # Public: Get the Restforce::DB::Mapping entry for the specified
        # database model.
        #
        # database_model - A Class compatible with ActiveRecord::Base.
        #
        # Returns a Restforce::DB::Mapping.
        def [](database_model)
          collection[database_model]
        end

        # Public: Iterate through all registered Restforce::DB::Mappings.
        #
        # Yields one Mapping for each database-to-Salesforce mapping.
        # Returns nothing.
        def each
          collection.each do |database_model, record_type|
            yield database_model.name, record_type
          end
        end

      end

      self.collection ||= {}

      attr_reader(
        :database_model,
        :salesforce_model,
        :database_record_type,
        :salesforce_record_type,
        :associations,
        :conditions,
      )
      attr_writer :root

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
        @root = options.fetch(:root) { false }

        @types = {
          database_model   => :database,
          salesforce_model => :salesforce,
        }

        self.class.collection[database_model] = self
      end

      # Public: Get a list of the relevant Salesforce field names for this
      # mapping.
      #
      # Returns an Array.
      def salesforce_fields
        @fields.values + @associations.values
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
        @root
      end

      # Public: Build a normalized Hash of attributes from the appropriate set
      # of mappings. The keys of the resulting mapping Hash will correspond to
      # the database column names.
      #
      # in_format - A String or Class reflecting the record type from which the
      #             attribute Hash is being compiled.
      #
      # Yields the attribute name.
      # Returns a Hash.
      def attributes(from_format)
        use_mappings =
          case @types[from_format]
          when :salesforce
            @fields
          when :database
            # Generate a mapping of database column names to record attributes.
            database_fields.zip(database_fields)
          else
            raise ArgumentError
          end

        use_mappings.each_with_object({}) do |(attribute, mapping), values|
          values[attribute] = yield(mapping)
        end
      end

      # Public: Convert a Hash of attributes to a format compatible with a
      # specific platform.
      #
      # to_format  - A String or Class reflecting the record type for which the
      #              attribute Hash is being compiled.
      # attributes - A Hash of attributes, with keys corresponding to the
      #              normalized attribute names.
      #
      # Examples
      #
      #   mapping = Mapping.new(MyClass, "Object__c", some_key: "SomeField__c")
      #
      #   mapping.convert("Object__c", some_key: "some value")
      #   # => { "Some_Field__c" => "some value" }
      #
      #   mapping.convert(MyClass, some_key: "some other value")
      #   # => { some_key: "some other value" }
      #
      # Returns a Hash.
      def convert(to_format, attributes)
        case @types[to_format]
        when :database
          attributes.dup
        when :salesforce
          @fields.each_with_object({}) do |(attribute, mapping), converted|
            next unless attributes.key?(attribute)
            converted[mapping] = attributes[attribute]
          end
        else
          raise ArgumentError
        end
      end

      # Public: Get a Synchronizer for the record types captured by this
      # Mapping.
      #
      # Returns a Restforce::DB::Synchronizer.
      def synchronizer
        @synchronizer ||= Synchronizer.new(@database_record_type, @salesforce_record_type)
      end

    end

  end

end
