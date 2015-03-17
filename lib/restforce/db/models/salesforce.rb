module Restforce

  module DB

    module Models

      class Salesforce < Base

        def find(id)
          record = DB.client.query("select #{lookups} from #{@model} where Id = '#{id}'").first
          return unless record

          Instances::Salesforce.new(record, @mappings)
        end

        private

        def lookups
          (Instances::Salesforce::INTERNAL_ATTRIBUTES + @mappings.keys).join(", ")
        end

      end

    end

  end

end
