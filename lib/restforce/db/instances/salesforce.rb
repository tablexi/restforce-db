module Restforce

  module DB

    module Instances

      # Public: Restforce::DB::Instances::Salesforce serves as a wrapper for
      # Salesforce objects, exposing a common API to reconcile record attributes
      # with ActiveRecord instances.
      class Salesforce < Base

        INTERNAL_ATTRIBUTES = %w(
          Id
          SystemModstamp
        ).freeze

        # Public: Get the time of the last update to this record.
        #
        # Returns a Time-compatible object.
        def last_update
          @record.SystemModstamp
        end

      end

    end

  end

end
