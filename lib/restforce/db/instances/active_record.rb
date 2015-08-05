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
          return uuid unless synced?
          @record.send(@mapping.lookup_column)
        end

        # Public: Get a unique identifier for this record. This value should
        # be consistent for the specific ActiveRecord object passed to this
        # instance.
        #
        # Returns nothing.
        def uuid
          "#{@record_type}::#{@record.id}"
        end

        # Public: Update the instance with the passed attributes.
        #
        # attributes - A Hash mapping attribute names to values.
        #
        # Returns self.
        # Raises if the update fails for any reason.
        def update!(attributes)
          record.assign_attributes(attributes)
          return self unless record.changed?

          super attributes
        end

        # Public: Get the time of the last update to this record.
        #
        # Returns a Time-compatible object.
        def last_update
          @record.updated_at
        end

        # Public: Has this record been synced to a Salesforce record?
        #
        # Returns a Boolean.
        def synced?
          @record.send(:"#{@mapping.lookup_column}?")
        end

        # Public: Was this record most recently updated by Restforce::DB's
        # workflow?
        #
        # Returns a Boolean.
        def updated_internally?
          last_synchronize.to_i >= last_update.to_i
        end

        # Public: Bump the synchronization timestamp on the record.
        #
        # Returns nothing.
        def after_sync
          @record.touch(:synchronized_at)
          super
        end

        private

        # Internal: Get the time of the last synchronization update to this
        # record.
        #
        # Returns a Time-compatible object.
        def last_synchronize
          @record.synchronized_at
        end

      end

    end

  end

end
