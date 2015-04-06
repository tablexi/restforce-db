module Restforce

  module DB

    # Restforce::DB::Collector is responsible for grabbing the attributes from
    # recently-updated records for purposes of synchronization. It relies on the
    # mappings configured in instances of Restforce::DB::RecordTypes::Base to
    # locate recently-updated records and fetch their attributes.
    class Collector

      attr_reader :last_run

      # Public: Initialize a new Restforce::DB::Collector.
      #
      # mapping - A Restforce::DB::Mapping instance.
      # runner  - A Restforce::DB::Runner instance.
      def initialize(mapping, runner = Runner.new)
        @mapping = mapping
        @runner = runner
      end

      # Public: Run the collection process, pulling in records from Salesforce
      # and the database to determine the lists of attributes to apply to all
      # mapped records.
      #
      # accumulator - A Hash-like accumulator object.
      #
      # Returns a Hash mapping Salesforce IDs to Restforce::DB::Accumulators.
      def run(accumulator = nil)
        @accumulated_changes = accumulator || accumulated_changes

        @runner.run(@mapping) do |run|
          run.salesforce_records { |record| accumulate(record) }
          run.database_records { |record| accumulate(record) }
        end

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

    end

  end

end
