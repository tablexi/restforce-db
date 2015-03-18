module Restforce

  module DB

    module Instances

      # Public: Restforce::DB::Instances::ActiveRecord serves as a wrapper for
      # ActiveRecord::Base-compatible objects, exposing a common API to
      # reconcile record attributes with Salesforce instances.
      class ActiveRecord < Base

        # Public: Get the time of the last update to this record.
        #
        # Returns a Time-compatible object.
        def last_update
          @record.updated_at
        end

        # Public: Get a description of the expected attribute Hash format.
        #
        # Returns a Symbol.
        def conversion
          :database
        end

      end

    end

  end

end
