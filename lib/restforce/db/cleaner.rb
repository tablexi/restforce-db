module Restforce

  module DB

    # Restforce::DB::Cleaner is responsible for culling the matching database
    # records when a Salesforce record is no longer available to synchronize
    # for a specific mapping.
    class Cleaner < Task

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

      # Salesforce can take a few minutes to register record deletion. This
      # buffer gives us a window of time (in seconds) to look back and see
      # records which may not have been visible in previous runs.
      DELETION_READ_BUFFER = 3 * 60

      # Internal: Get the IDs of records which have been removed from Salesforce
      # for this mapping within the DELETION_BUFFER for this run.
      #
      # Returns an Array of IDs.
      def deleted_salesforce_ids
        return [] unless @runner.after

        response = DB.client.get_deleted_between(
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

        # NOTE: We need to query for _valid_ records first, because, in the
        # scenario where a record is updated _between_ the two queries running,
        # the change to the SystemModstamp will prevent the record from being
        # picked up in the second query. In this situation, it's safer to omit
        # the ID from the list of aggregate IDs than it is to omit it from the
        # list of valid IDs.
        valid_ids = valid_salesforce_ids
        all_ids = all_salesforce_ids

        invalid_ids = all_ids - valid_ids
        DB.logger.debug "(REPORTED INVALID) #{@mapping.salesforce_model} #{invalid_ids.inspect}" if invalid_ids.any?

        invalid_ids = confirmed_invalid_salesforce_ids(invalid_ids)
        DB.logger.debug "(CONFIRMED INVALID) #{@mapping.salesforce_model} #{invalid_ids.inspect}" if invalid_ids.any?

        invalid_ids
      end

      # In order to ensure that we don't generate any SOQL queries which are too
      # long to send across the wire to Salesforce, we need to batch IDs for our
      # queries. For a conservative cap of 8,000 characters per GET query, at 27
      # encoded characters per supplied ID (18 characters and 3 three-character
      # entities), 250 IDs gives us a buffer of around 1250 spare characters to
      # work with for the rest of the URL and query string.
      #
      # In practice, there should rarely/never be this many invalidated records
      # at once during a single worker run.
      MAXIMUM_IDS_PER_QUERY = 250

      # Internal: Get the IDs of records which have been proposed as invalid and
      # do not in fact appear in response to a time-insensitive query with the
      # requisite conditions applied.
      #
      # NOTE: This double-check step is necessary to prevent an inaccurate
      # Salesforce server clock from sending records back in time and forcing
      # them to show up in a query running after-the-fact.
      #
      # proposed_invalid_ids - An Array of String Salesforce IDs to test against
      #                        the Salesforce server.
      #
      # Returns an Array of IDs.
      def confirmed_invalid_salesforce_ids(proposed_invalid_ids)
        proposed_invalid_ids.each_slice(MAXIMUM_IDS_PER_QUERY).inject([]) do |invalid_ids, ids|
          # Get a subset of the proposed list of IDs that corresponds to
          # records which are still valid for any parallel mapping.
          valid_ids = parallel_mappings.flat_map do |mapping|
            mapping.salesforce_record_type.all(
              conditions: "Id in ('#{ids.join("','")}')",
            ).map(&:id)
          end

          invalid_ids + (ids - valid_ids)
        end
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
      # Returns an Array of Mappings.
      def parallel_mappings
        Registry[@mapping.database_model].select do |mapping|
          mapping.salesforce_model == @mapping.salesforce_model
        end
      end

    end

  end

end
