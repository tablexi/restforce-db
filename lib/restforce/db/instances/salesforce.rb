module Restforce

  module DB

    module Instances

      class Salesforce < Base

        INTERNAL_ATTRIBUTES = %w(
          Id
          SystemModstamp
        ).freeze

        def update!(attributes)
          @record.client.update!(
            @record.attributes["type"],
            attributes.merge("Id" => @record.Id),
          )
          @record.merge! attributes
        end

        def copy!(record)
          update! attributes_from(record.attributes)
        end

        def last_update
          @record.SystemModstamp
        end

      end

    end

  end

end
