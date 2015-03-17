module Restforce

  module DB

    module Models

      class Salesforce < Base

        def find(id)
          Instances::Salesforce.new(
            DB.client.query("select #{lookups} from #{@model} where Id = '#{id}'").first,
            @mappings,
          )
        end

        private

        def lookups
          (Instances::Salesforce::INTERNAL_ATTRIBUTES + @mappings.keys).join(", ")
        end

      end

    end

  end

end
