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

        database_model, record_id = parsed_uuid(synchronization_id)
        return unless valid_model?(database_model)

        # If the instance is already synchronized, then we just want to wipe the
        # Synchronization ID and proceed to the next instance.
        if instance.synced?
          instance.update!("SynchronizationId__c" => nil)
          return
        end

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

      # Internal: Does the passed database model correspond to the model defined
      # on the mapping?
      #
      # database_model - A String name of an ActiveRecord::Base subclass.
      #
      # Returns a Boolean.
      def valid_model?(database_model)
        database_model == @mapping.database_model.to_s
      end

      # Internal: Parse a UUID into a database model and corresponding record
      # identifier.
      #
      # uuid - A String UUID, in the format "<Model>::<Id>"
      #
      # Returns an Array of two Strings.
      def parsed_uuid(uuid)
        components = uuid.split("::")

        database_model = components[0..-2].join("::")
        id = components.last

        [database_model, id]
      end

    end

  end

end
