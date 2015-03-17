module Restforce

  module DB

    module Instances

      class Salesforce < Base

        INTERNAL_ATTRIBUTES = %w(
          Id
          SystemModstamp
        ).freeze

        def last_update
          @record.SystemModstamp
        end

      end

    end

  end

end
