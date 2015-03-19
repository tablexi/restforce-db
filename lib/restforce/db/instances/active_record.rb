module Restforce

  module DB

    module Instances

      # Restforce::DB::Instances::ActiveRecord serves as a wrapper for
      # ActiveRecord::Base-compatible objects, exposing a common API to
      # reconcile record attributes with Salesforce instances.
      class ActiveRecord < Base

        # Public: Get a common identifier for this record.
        #
        # Returns a String.
        def id
          @record.salesforce_id
        end

        # Public: Get the time of the last update to this record.
        #
        # Returns a Time-compatible object.
        def last_update
          @record.updated_at
        end

        private

        # Internal: Get a description of the expected attribute Hash format.
        #
        # Returns a Symbol.
        def conversion
          :database
        end

      end

    end

  end

end
