module Restforce

  module DB

    module Models

      # Public: Restforce::DB::Models::ActiveRecord serves as a wrapper for a
      # single ActiveRecord::Base-compatible class, allowing for standard record
      # lookups and attribute mappings.
      class ActiveRecord < Base

        # Public: Find the instance of this ActiveRecord model corresponding to
        # the passed salesforce_id.
        #
        # salesforce_id - The id of the record in Salesforce.
        #
        # Returns nil or a Restforce::DB::Instances::ActiveRecord instance.
        def find(id)
          record = @model.find_by(salesforce_id: id)
          return nil unless record

          Instances::ActiveRecord.new(record, @mappings)
        end

      end

    end

  end

end
