module Restforce

  module DB

    # Restforce::DB::Attacher is responsible for cleaning up any orphaned
    # upserted Salesforce records with the database records that they were
    # originally supposed to be attached to. This allows us to successfully
    # handle cases where a request timeout or partial failure would otherwise
    # leave an upserted Salesforce record stranded without a related database
    # record.
    class Attacher < Task

      # Public: Run the re-attachment process for any unsynchronized Salesforce
      # records which have an external upsert ID.
      #
      # Returns nothing.
      def run(*_)
        return if @mapping.strategy.passive?

        @runner.run(@mapping) do |run|
          run.salesforce_instances.each { |instance| attach(instance) }
        end
      end

      private

      # Internal: Attach the passed Salesforce instance to a related database
      # record.
      #
      # instance - A Restforce::DB::Instances::Salesforce.
      #
      # Returns nothing.
      def attach(instance)
        synchronization_id = instance.record.SynchronizationId__c

        return unless synchronization_id
        return unless valid_model?(synchronization_id)

        # If the instance is already synchronized, then we just want to wipe the
        # Synchronization ID and proceed to the next instance.
        if instance.synced?
          instance.update!("SynchronizationId__c" => nil)
          return
        end

        record_id = synchronization_id.split("::").last
        record = @mapping.database_model.find_by(
          id: record_id,
          @mapping.lookup_column => nil,
        )

        if record
          attach_to = Instances::ActiveRecord.new(@mapping.database_model, record, @mapping)
          attach_to.update!(@mapping.lookup_column => instance.id)
        end

        instance.update!("SynchronizationId__c" => nil)
      rescue Faraday::Error::ClientError => e
        DB.logger.error(SynchronizationError.new(e, instance))
      end

      # Internal: Does the synchronization UUID correspond to a valid record for
      # the database model on the mapping?
      #
      # synchronization_id - A String in the format "<Model>::<ID>"
      #
      # Returns a Boolean.
      def valid_model?(synchronization_id)
        synchronization_id.split("::").first == @mapping.database_model.to_s
      end

    end

  end

end
