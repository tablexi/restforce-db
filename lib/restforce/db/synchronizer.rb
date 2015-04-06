module Restforce

  module DB

    # Restforce::DB::Synchronizer is responsible for synchronizing the records
    # in Salesforce with the records in the database. It relies on the mappings
    # configured in instances of Restforce::DB::RecordTypes::Base to create and
    # update records with the appropriate values.
    class Synchronizer

      # Public: Initialize a new Restforce::DB::Synchronizer.
      #
      # mapping - A Restforce::DB::Mapping.
      # runner  - A Restforce::DB::Runner.
      def initialize(mapping, runner = Runner.new)
        @mapping = mapping
        @runner = runner
      end

      # Public: Run the synchronize process, pulling in records from Salesforce
      # and the database to determine which records need to be created and/or
      # updated.
      #
      # NOTE: We bootstrap our record lookups to the exact same timespan, and
      # run the Salesforce sync into the database first. This has the effect of
      # overwriting recent changes to the database, in the event that Salesforce
      # has also been updated since the last sync.
      #
      # Returns the Time the run was performed.
      def run
        @runner.run(@mapping) do |run|
          run.salesforce_records do |record|
            @mapping.database_record_type.sync!(record)
          end
          run.database_records do |record|
            @mapping.salesforce_record_type.sync!(record)
          end
        end
      end

    end

  end

end
