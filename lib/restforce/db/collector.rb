module Restforce

  module DB

    # Restforce::DB::Collector is responsible for grabbing the attributes from
    # recently-updated records for purposes of synchronization. It relies on the
    # mappings configured in instances of Restforce::DB::RecordTypes::Base to
    # locate recently-updated records and fetch their attributes.
    class Collector

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
      # Returns a Hash mapping Salesforce ID/type combinations to accumulators.
      def run(accumulator = nil)
        @accumulated_changes = accumulator || accumulated_changes

        @runner.run(@mapping) do |run|
          run.salesforce_instances.each { |instance| accumulate(instance) }
          run.database_instances.each { |instance| accumulate(instance) }
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
        accumulated_changes[key_for(record)].store(
          record.last_update,
          @mapping.convert(@mapping.salesforce_model, record.attributes),
        )
      end

      # Internal: Get a unique key with enough information to look up the passed
      # record in Salesforce.
      #
      # record - A Restforce::DB::Instances::Base.
      #
      # Returns an Object.
      def key_for(record)
        [record.id, record.mapping.salesforce_model]
      end

    end

  end

end
