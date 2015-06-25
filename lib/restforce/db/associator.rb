module Restforce

  module DB

    # Restforce::DB::Associator is responsible for determining when one or more
    # associations have been updated to point to a new Salesforce/database
    # record, and propagate the modification to the opposite system when this
    # occurs.
    class Associator < Task

      # Public: Run the re-association process, pulling in records from
      # Salesforce and the database to determine the most recently attached
      # association, then propagating the change between systems.
      #
      # Returns nothing.
      def run(*_)
        return if belongs_to_associations.empty?

        @runner.run(@mapping) do |run|
          run.salesforce_instances.each { |instance| verify_associations(instance) }
          run.database_instances.each { |instance| verify_associations(instance) }
        end
      end

      private

      # Internal: Ensure integrity between the lookup columns in Salesforce and
      # the synchronized records in the database. Skips records which have only
      # been updated by Restforce::DB itself.
      #
      # instance - A Restforce::DB::Instances::Base.
      #
      # Returns nothing.
      def verify_associations(instance)
        return unless instance.synced?
        return if instance.updated_internally?

        database_instance, salesforce_instance = synchronized_instances(instance)
        return unless database_instance && salesforce_instance

        sync_associations(database_instance, salesforce_instance)
      end

      # Internal: Given an instance for one system, find its synchronized pair
      # in the other system.
      #
      # instance - A Restforce::DB::Instances::Base.
      #
      # Returns an Array containing one Restforce::DB::Instances::ActiveRecord
      #   and one Restforce::DB::Instances::Salesforce, in that order.
      def synchronized_instances(instance)
        case instance
        when Restforce::DB::Instances::Salesforce
          [@mapping.database_record_type.find(instance.id), instance]
        when Restforce::DB::Instances::ActiveRecord
          [instance, @mapping.salesforce_record_type.find(instance.id)]
        end
      end

      # Internal: Given a database record and corresponding Salesforce data,
      # synchronize the record associations in whichever system has the least
      # recent data.
      #
      # database_instance   - A Restforce::DB::Instances::ActiveRecord.
      # salesforce_instance - A Restforce::DB::Instances::Salesforce.
      #
      # Returns nothing.
      def sync_associations(database_instance, salesforce_instance)
        ids = belongs_to_association_ids(database_instance)
        return if ids.all? { |field, id| salesforce_instance.record[field] == id }

        if database_instance.last_update > salesforce_instance.last_update
          salesforce_instance.update!(ids)
        else
          database_record = database_instance.record
          belongs_to_associations.each do |association|
            association.build(database_record, salesforce_instance.record)
          end
          database_record.save!
        end
      rescue ActiveRecord::ActiveRecordError, Faraday::Error::ClientError => e
        DB.logger.error(SynchronizationError.new(e, salesforce_instance))
      end

      # Internal: Get a Hash of associated lookup IDs for the passed database
      # record.
      #
      # database_instance - A Restforce::DB::Instances::ActiveRecord.
      #
      # Returns a Hash.
      def belongs_to_association_ids(database_instance)
        belongs_to_associations.inject({}) do |ids, association|
          ids.merge(association.lookups(database_instance.record))
        end
      end

      # Internal: Get a list of the BelongsTo associations defined for the
      # target mapping.
      #
      # Returns an Array of Restforce::DB::Association::BelongsTo objects.
      def belongs_to_associations
        @belongs_to_associations ||= @mapping.associations.select do |association|
          association.is_a?(Restforce::DB::Associations::BelongsTo)
        end
      end

    end

  end

end
