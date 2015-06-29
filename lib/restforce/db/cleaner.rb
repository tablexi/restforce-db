module Restforce

  module DB

    # Restforce::DB::Cleaner is responsible for culling the matching database
    # records when a Salesforce record is no longer available to synchronize
    # for a specific mapping.
    class Cleaner < Task

      # Salesforce can take a few minutes to register record deletion. This
      # buffer gives us a window of time (in seconds) to look back and see
      # records which may not have been visible in previous runs.
      DELETION_READ_BUFFER = 3 * 60

      # Public: Run the database culling loop for this mapping.
      #
      # Returns nothing.
      def run(*_)
        @mapping.database_record_type.destroy_all(dropped_salesforce_ids)
      end

      private

      # Internal: Get a comprehensive list of Salesforce IDs corresponding to
      # records which should be dropped from synchronization for this mapping.
      #
      # Returns an Array of IDs.
      def dropped_salesforce_ids
        deleted_salesforce_ids + invalid_salesforce_ids
      end

      # Internal: Get the IDs of records which have been removed from Salesforce
      # for this mapping within the DELETION_BUFFER for this run.
      #
      # Returns an Array of IDs.
      def deleted_salesforce_ids
        return [] unless @runner.after

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
        return [] if @mapping.conditions.empty? || @mapping.strategy.passive?

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
