module Restforce

  module DB

    module Models

      class ActiveRecord < Base

        def find(id)
          record = @model.find_by(salesforce_id: id)
          return nil unless record

          Instances::ActiveRecord.new(record, @mappings)
        end

      end

    end

  end

end
