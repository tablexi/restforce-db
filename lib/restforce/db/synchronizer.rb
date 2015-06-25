module Restforce

  module DB

    # Restforce::DB::Synchronizer is responsible for synchronizing the records
    # in Salesforce with the records in the database. It relies on the mappings
    # configured in instances of Restforce::DB::RecordTypes::Base to create and
    # update records with the appropriate values.
    class Synchronizer < Task

      # Public: Synchronize records for the current mapping from a Hash of
      # record descriptors to attributes.
      #
      # NOTE: Synchronizer assumes that the propagation step has done its job
      # correctly. If we can't locate a database record for a specific
      # Salesforce ID, we assume it shouldn't be synchronized.
      #
      # changes - A Hash, with keys composed of a Salesforce ID and model name,
      #           with Restforce::DB::Accumulator objects as values.
      #
      # Returns nothing.
      def run(changes)
        changes.each do |(id, salesforce_model), accumulator|
          next unless salesforce_model == @mapping.salesforce_model

          database_instance = @mapping.database_record_type.find(id)
          salesforce_instance = @mapping.salesforce_record_type.find(id)

          next unless database_instance && salesforce_instance
          next unless up_to_date?(database_instance, accumulator)
          next unless up_to_date?(salesforce_instance, accumulator)

          update(database_instance, accumulator)
          update(salesforce_instance, accumulator)
        end
      end

      # Public: Update the passed instance with the accumulated attributes
      # from a synchronization run.
      #
      # instance    - An instance of Restforce::DB::Instances::Base.
      # accumulator - A Restforce::DB::Accumulator.
      #
      # Returns nothing.
      def update(instance, accumulator)
        return unless accumulator.changed?(instance.attributes)

        current_attributes = accumulator.current(instance.attributes)
        attributes = @mapping.convert(instance.record_type, current_attributes)

        instance.update!(attributes)
        @runner.cache_timestamp instance
      rescue ActiveRecord::ActiveRecordError, Faraday::Error::ClientError => e
        DB.logger.error(SynchronizationError.new(e, instance))
      end

      private

      # Internal: Is the passed instance up-to-date with the passed accumulator?
      # Defaults to true if the most recent change to the instance was by the
      # Restforce::DB worker.
      #
      # Returns a Boolean.
      def up_to_date?(instance, accumulator)
        instance.updated_internally? || accumulator.up_to_date_for?(instance.last_update)
      end

    end

  end

end
