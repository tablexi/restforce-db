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

        # Public: Get the time of the last update to this record.
        #
        # Returns a Time-compatible object.
        def last_update
          Time.parse(@record.SystemModstamp)
        end

        private

        # Internal: Get a description of the expected attribute Hash format.
        #
        # Returns a Symbol.
        def conversion
          :salesforce
        end

      end

    end

  end

end
