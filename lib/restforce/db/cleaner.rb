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
        return if @mapping.conditions.empty? || @strategy.passive?
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
