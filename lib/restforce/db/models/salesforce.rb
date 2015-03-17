module Restforce

  module DB

    module Models

      # Public: Restforce::DB::Models::Salesforce serves as a wrapper for a
      # single Salesforce object class, allowing for standard record lookups and
      # attribute mappings.
      class Salesforce < Base

        # Public: Find the Salesforce record corresponding to the passed id.
        #
        # id - The id of the record in Salesforce.
        #
        # Returns nil or a Restforce::DB::Instances::Salesforce instance.
        def find(id)
          record = DB.client.query("select #{lookups} from #{@model} where Id = '#{id}'").first
          return unless record

          Instances::Salesforce.new(record, @mappings)
        end

        private

        # Internal: Get a String of values to look up when the record is
        # fetched from Salesforce. Includes all configured mappings and a
        # handful of attributes for internal use.
        #
        # Returns a String.
        def lookups
          (Instances::Salesforce::INTERNAL_ATTRIBUTES + @mappings.keys).join(", ")
        end

      end

    end

  end

end
