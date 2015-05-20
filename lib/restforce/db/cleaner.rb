module Restforce

  module DB

    # Restforce::DB::Cleaner is responsible for culling the matching database
    # records when a Salesforce record has been deleted or otherwise no longer
    # meets the sync conditions for a mapping.
    class Cleaner

      # Salesforce can take a few minutes to register record deletion. This
      # buffer gives us a window of time (in seconds) to look back and see
      # records which may not have been visible in previous runs.
      DELETION_READ_BUFFER = 3 * 60

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
        drop_deleted_records
        drop_invalid_records
      end

      private

      # Internal: Destroy any database records corresponding to Salesforce
      # records which have been deleted within the Salesforce environment.
      #
      # Returns nothing.
      def drop_deleted_records
        return unless @runner.after
        @mapping.database_record_type.destroy_all(deleted_salesforce_ids)
      end

      # Internal: Destroy any database records corresponding to Salesforce
      # records which have been modified such that they no longer meet the
      # conditions defined for this mapping.
      #
      # Returns nothing.
      def drop_invalid_records
        return if @mapping.conditions.empty? || @strategy.passive?
        @mapping.database_record_type.destroy_all(invalid_salesforce_ids)
      end

      # Internal: Get the IDs of records which have been removed from Salesforce
      # for this mapping within the DELETION_BUFFER for this run.
      #
      # Returns an Array of IDs.
      def deleted_salesforce_ids
        response = Restforce::DB.client.get_deleted_between(
          @mapping.salesforce_model,
          @runner.after - DELETION_READ_BUFFER,
          @runner.before,
        )

        response.deletedRecords.map(&:id)
      end

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
        @mapping.unscoped { salesforce_ids(@mapping) }
      end

      # Internal: Get the IDs of the recently-modified Salesforce records for
      # mappings between the same object types.
      #
      # Returns an Array of IDs.
      def valid_salesforce_ids
        parallel_mappings.flat_map { |mapping| salesforce_ids(mapping) }
      end

      # Internal: Get the IDs of the recently-modified Salesforce records which
      # meet the conditions for this mapping.
      #
      # mapping - A Restforce::DB::Mapping.
      #
      # Returns an Array of IDs.
      def salesforce_ids(mapping)
        @runner.run(mapping) do |run|
          run.salesforce_instances.map(&:id)
        end
      end

      # Internal: Get a list of mappings between identical Salesforce and
      # database record types. This allows us to protect against inadvertently
      # removing records which belong to a parallel mapping on the same
      # ActiveRecord class.
      #
      # Rturns an Array of Mappings.
      def parallel_mappings
        Registry[@mapping.database_model].select do |mapping|
          mapping.salesforce_model == @mapping.salesforce_model
        end
      end

    end

  end

end
