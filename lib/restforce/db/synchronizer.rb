module Restforce

  module DB

    # Restforce::DB::Synchronizer is responsible for synchronizing the records
    # in Salesforce with the records in the database. It relies on the mappings
    # configured in instances of Restforce::DB::RecordTypes::Base to create and
    # update records with the appropriate values.
    class Synchronizer

      attr_reader :last_run

      # Public: Initialize a new Restforce::DB::Synchronizer.
      #
      # database_record_type   - A Restforce::DB::RecordTypes::ActiveRecord
      #                          instance.
      # salesforce_record_type - A Restforce::DB::RecordTypes::Salesforce
      #                          instance.
      # last_run_time          - A Time object reflecting the time of the most
      #                          recent synchronization run. Runs will only
      #                          synchronize data more recent than this stamp.
      def initialize(database_record_type, salesforce_record_type, last_run_time = nil)
        @database_record_type = database_record_type
        @salesforce_record_type = salesforce_record_type
        @last_run = last_run_time
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
      # options - A Hash of options for configuring the run. Currently unused.
      #
      # Returns the Time the run was performed.
      def run(_options = {})
        run_time = Time.now

        @salesforce_record_type.each(after: last_run, before: run_time) do |record|
          @database_record_type.sync!(record)
        end
        @database_record_type.each(after: last_run, before: run_time) do |record|
          @salesforce_record_type.sync!(record)
        end

        @last_run = run_time
      end

    end

  end

end
