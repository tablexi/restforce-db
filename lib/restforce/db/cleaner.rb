module Restforce

  module DB

    # Restforce::DB::Cleaner is responsible for culling the matching database
    # records when a Salesforce record no longer meets the sync conditions.
    class Cleaner

      # Public: Initialize a Restforce::DB::Cleaner.
      #
      # mapping - A Restforce::DB::Mapping.
      # runner  - A Restforce::DB::Runner.
      def initialize(mapping, runner = Runner.new)
        @mapping = mapping
        @strategy = mapping.strategy
        @runner = runner
      end

      # Public: Run the database culling loop for this mapping.
      #
      # Returns nothing.
      def run
        return if @strategy.passive?
        @mapping.database_record_type.destroy_all(invalid_salesforce_ids)
      end

      private

      # Internal: Get the IDs of records which are in the larger collection
      # of Salesforce records, but which do not meet the specific conditions for
      # this mapping.
      #
      # Returns an Array of IDs.
      def invalid_salesforce_ids
        all_salesforce_ids - valid_salesforce_ids
      end

      # Internal: Get the IDs of all recently-modified Salesforce records
      # corresponding to the object type for this mapping.
      #
      # Returns an Array of IDs.
      def all_salesforce_ids
        all_ids = []

        @mapping.unscoped do |map|
          @runner.run(map) do |run|
            run.salesforce_instances { |instance| all_ids << instance.id }
          end
        end

        all_ids
      end

      # Internal: Get the IDs of the recently-modified Salesforce records which
      # meet the conditions for this mapping.
      #
      # Returns an Array of IDs.
      def valid_salesforce_ids
        valid_ids = []

        @runner.run(@mapping) do |run|
          run.salesforce_instances { |instance| valid_ids << instance.id }
        end

        valid_ids
      end

    end

  end

end
