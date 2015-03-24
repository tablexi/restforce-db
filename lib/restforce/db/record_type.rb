module Restforce

  module DB

    # Restforce::DB::RecordType is an abstraction for a two-way binding between
    # an ActiveRecord class and a Salesforce object type. It provides an
    # interface for mapping database columns to Salesforce fields.
    class RecordType

      class << self

        include Enumerable
        attr_accessor :collection

        # Public: Get the Restforce::DB::RecordType entry for the specified
        # database model.
        #
        # database_model - A Class compatible with ActiveRecord::Base.
        #
        # Returns a Restforce::DB::RecordType.
        def [](database_model)
          collection[database_model]
        end

        # Public: Iterate through all registered Restforce::DB::RecordTypes.
        #
        # Yields one RecordType for each database-to-Salesforce mapping.
        # Returns nothing.
        def each
          collection.each do |database_model, record_type|
            yield database_model.name, record_type
          end
        end

      end

      self.collection ||= {}
      attr_reader :mapping, :synchronizer

      # Public: Initialize and register a Restforce::DB::RecordType.
      #
      # database_model   - A Class compatible with ActiveRecord::Base.
      # salesforce_model - A String name of an object type in Salesforce.
      # mappings         - A Hash of mappings between database columns and
      #                    fields in Salesforce.
      def initialize(database_model, salesforce_model, **mappings)
        @mapping = Mapping.new(mappings)
        @database_record_type = RecordTypes::ActiveRecord.new(database_model, @mapping)
        @salesforce_record_type = RecordTypes::Salesforce.new(salesforce_model, @mapping)
        @synchronizer = Synchronizer.new(@database_record_type, @salesforce_record_type)

        self.class.collection[database_model] = self
      end

      # Public: Append the passed mappings to this model.
      #
      # mappings - A Hash of database column names mapped to Salesforce fields.
      #
      # Returns nothing.
      def add_mappings(mappings)
        @mapping.add_mappings mappings
      end

      # Public: Synchronize the records between the database and Salesforce.
      #
      # options - A Hash of options to pass to the synchronizer.
      #
      # Returns nothing.
      def synchronize(options)
        @synchronizer.run(options)
      end

    end

  end

end
