module Restforce

  module DB

    module Instances

      # Restforce::DB::Instances::Salesforce serves as a wrapper for Salesforce
      # objects, exposing a common API to reconcile record attributes with
      # ActiveRecord instances.
      class Salesforce < Base

        INTERNAL_ATTRIBUTES = %w(
          Id
          SystemModstamp
        ).freeze

        # Public: Get a common identifier for this record.
        #
        # Returns a String.
        def id
          @record.Id
        end

        # Public: Update the instance with the passed attributes.
        #
        # attributes - A Hash mapping attribute names to values.
        #
        # Returns self.
        # Raises if the update fails for any reason.
        def update!(attributes)
          super FieldProcessor.new.process(@record_type, attributes)
        end

        # Public: Get the time of the last update to this record.
        #
        # Returns a Time-compatible object.
        def last_update
          Time.parse(@record.SystemModstamp)
        end

        # Public: Get the time of the last synchronization update to this
        # record.
        #
        # Returns a Time-compatible object.
        def last_synchronize
          last_update
        end

        # Public: Has this record been synced with Salesforce?
        #
        # Returns a Boolean.
        def synced?
          @mapping.database_model.exists?(@mapping.lookup_column => id)
        end

      end

    end

  end

end
