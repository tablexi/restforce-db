module Restforce

  module DB

    # Restforce::DB::Initializer is responsible for ensuring that both systems
    # are populated with the same records at the root level. It iterates through
    # recently added or updated records in each system for a mapping, and
    # creates a matching record in the other system, when necessary.
    class Initializer

      # Public: Initialize a Restforce::DB::Initializer.
      #
      # mapping - A Restforce::DB::Mapping.
      # runner  - A Restforce::DB::Runner.
      def initialize(mapping, runner = Runner.new)
        @mapping = mapping
        @runner = runner
      end

      # Public: Run the initialization loop for this mapping.
      #
      # Returns nothing.
      def run
        return unless @mapping.root?

        @runner.run(@mapping) do |run|
          run.salesforce_records { |record| create_in_database(record) }
          run.database_records { |record| create_in_salesforce(record) }
        end
      end

      private

      # Internal: Attempt to create a partner record in the database for the
      # passed Salesforce record. Does nothing if the Salesforce record has
      # already been synchronized into the system at least once.
      #
      # record - A Restforce::DB::Instances::Salesforce.
      #
      # Returns nothing.
      def create_in_database(record)
        return if record.synced?
        @mapping.database_record_type.create!(record)
      end

      # Internal: Attempt to create a partner record in Salesforce for the
      # passed database record. Does nothing if the database record already has
      # an associated Salesforce record.
      #
      # record - A Restforce::DB::Instances::ActiveRecord.
      #
      # Returns nothing.
      def create_in_salesforce(record)
        return if record.synced?
        @mapping.salesforce_record_type.create!(record)
      end

    end

  end

end
