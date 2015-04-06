module Restforce

  module DB

    # Restforce::DB::Collector is responsible for grabbing the attributes from
    # recently-updated records for purposes of synchronization. It relies on the
    # mappings configured in instances of Restforce::DB::RecordTypes::Base to
    # locat recently updated records and fetch their attributes.
    class Collector

      attr_reader :last_run

      # Public: Initialize a new Restforce::DB::Collector.
      #
      # database_record_type   - A Restforce::DB::RecordTypes::ActiveRecord
      #                          instance.
      # salesforce_record_type - A Restforce::DB::RecordTypes::Salesforce
      #                          instance.
      # last_run_time          - A Time object reflecting the time of the most
      #                          recent collection run. Runs will only collect
      #                          data more recent than this stamp.
      def initialize(mapping, last_run_time = DB.last_run)
        @mapping = mapping
        @last_run = last_run_time
      end

      # Public: Run the collection process, pulling in records from Salesforce
      # and the database to determine the lists of attributes to apply to all
      # mapped records.
      #
      # options - A Hash of options for configuring the run. Valid keys are:
      #           :accumulator - An object in which to store the results of the
      #                          synchronization run.
      #           :delay       - An offset to apply to the time filters. Allows
      #                          the synchronization to account for server time
      #                          drift.
      #
      # Returns a Hash mapping Salesforce IDs to Restforce::DB::Accumulators.
      def run(options = {})
        @accumulated_changes = options.fetch(:accumulator) { accumulated_changes }
        before, after = run_times!(options)

        options = {
          after: after,
          before: before,
        }

        @mapping.salesforce_record_type.each(options) { |record| accumulate(record) }
        @mapping.database_record_type.each(options) { |record| accumulate(record) }

        accumulated_changes
      ensure
        # Clear out the results of this run so we start fresh next time.
        @accumulated_changes = nil
      end

      private

      # Internal: Get a Hash to collect accumulated changes.
      #
      # Returns a Hash of Hashes.
      def accumulated_changes
        @accumulated_changes ||= Hash.new { |h, k| h[k] = {} }
      end

      # Internal: Append the passed record's attributes to its accumulated list
      # of changesets.
      #
      # record - A Restforce::DB::Instances::Base.
      #
      # Returns nothing.
      def accumulate(record)
        accumulated_changes[record.id].store(
          record.last_update,
          @mapping.convert(@mapping.salesforce_model, record.attributes),
        )
      end

      # Internal: Get the "before" and "after" times for the current run,
      # updating the `last_run` timestamp to reflect this most recent run.
      #
      # options - A Hash of options for configuring the run. Valid keys are:
      #           :delay - An offset to apply to the time filters. Allows the
      #                    synchronization to account for server time drift.
      #
      # Returns an Array of two Time objects.
      def run_times!(options)
        run_time = Time.now
        delay = options.fetch(:delay) { 0 }
        before = run_time - delay
        after = last_run - delay if last_run
        @last_run = run_time

        [before, after]
      end

    end

  end

end
