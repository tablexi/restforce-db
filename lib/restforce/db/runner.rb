module Restforce

  module DB

    # Restforce::DB::Runner provides an abstraction for lookup timing during the
    # synchronization process. It provides methods for accessing only recently-
    # modified records within the context of a specific Mapping.
    class Runner

      attr_reader :last_run
      attr_accessor :before, :after

      # Public: Initialize a new Restforce::DB::Runner.
      #
      # delay         - A Numeric offet to apply to all record lookups. Can be
      #                 used to mitigate server timing issues.
      # last_run_time - A Time indicating the point at which new runs should
      #                 begin.
      def initialize(delay = 0, last_run_time = DB.last_run)
        @delay = delay
        @last_run = last_run_time
      end

      # Public: Indicate that a new phase of the run is beginning. Updates the
      # before/after timestamp to ensure that new lookups are properly filtered.
      #
      # Returns the new run Time.
      def tick!
        run_time = Time.now

        @before = run_time - @delay
        @after = last_run - @delay if @last_run

        @last_run = run_time
      end

      # Public: Grant access to recently-updated records for a specific mapping.
      #
      # mapping - A Restforce::DB::Mapping instance.
      #
      # Yields self, in the context of the passed mapping.
      # Returns nothing.
      def run(mapping)
        @mapping = mapping
        yield self
      ensure
        @mapping = nil
      end

      # Public: Iterate through recently-updated records for the Salesforce
      # record type defined by the current mapping.
      #
      # Yields a series of Restforce::DB::Instances::Salesforce objects.
      # Returns nothing.
      def salesforce_instances
        @mapping.salesforce_record_type.each(options) { |instance| yield instance }
      end

      # Public: Iterate through recently-updated records for the database model
      # record type defined by the current mapping.
      #
      # Yields a series of Restforce::DB::Instances::ActiveRecord objects.
      # Returns nothing.
      def database_instances
        @mapping.database_record_type.each(options) { |instance| yield instance }
      end

      private

      # Internal: Get a Hash of options to apply to record lookups.
      #
      # Returns a Hash.
      def options
        { after: after, before: before }
      end

    end

  end

end
