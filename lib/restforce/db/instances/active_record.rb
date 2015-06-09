module Restforce

  module DB

    module Instances

      # Restforce::DB::Instances::ActiveRecord serves as a wrapper for
      # ActiveRecord::Base-compatible objects, exposing a common API to
      # reconcile record attributes with Salesforce instances.
      class ActiveRecord < Base

        # Public: Get a common identifier for this record. If the record is
        # unsynchronized, returns a database-specific identifier.
        #
        # Returns a String.
        def id
          return "#{@record_type}::#{@record.id}" unless synced?
          @record.send(@mapping.lookup_column)
        end

        # Public: Has this record been synced to a Salesforce record?
        #
        # Returns a Boolean.
        def synced?
          @record.send(:"#{@mapping.lookup_column}?")
        end

        # Public: Get the time of the last update to this record.
        #
        # Returns a Time-compatible object.
        def last_update
          @record.updated_at
        end

        # Public: Get the time of the last synchronization update to this
        # record.
        #
        # Returns a Time-compatible object.
        def last_synchronize
          @record.synchronized_at
        end

        # Public: Bump the synchronization timestamp on the record.
        #
        # Returns nothing.
        def after_sync
          @record.touch(:synchronized_at)
          super
        end

      end

    end

  end

end
