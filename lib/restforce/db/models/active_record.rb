module Restforce

  module DB

    module Models

      class ActiveRecord < Base

        def find(id)
          Instances::ActiveRecord.new(
            @model.find_by(salesforce_id: id),
            @mappings,
          )
        end

      end

    end

  end

end
