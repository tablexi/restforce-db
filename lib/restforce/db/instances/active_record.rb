module Restforce

  module DB

    module Instances

      class ActiveRecord < Base

        def update!(attributes)
          @record.update! attributes
        end

        def copy!(record)
          update! attributes_from(record.attributes)
        end

        def last_update
          @record.updated_at
        end

      end

    end

  end

end
