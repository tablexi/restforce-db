module Restforce

  module DB

    module RecordTypes

      # Restforce::DB::RecordTypes::Salesforce serves as a wrapper for a single
      # Salesforce object class, allowing for standard record lookups and
      # attribute mappings.
      class Salesforce < Base

        # Public: Find the Salesforce record corresponding to the passed id.
        #
        # id - The id of the record in Salesforce.
        #
        # Returns nil or a Restforce::DB::Instances::Salesforce instance.
        def find(id)
          record = DB.client.query(
            "select #{lookups} from #{@record_type} where Id = '#{id}'",
          ).first

          return unless record

          Instances::Salesforce.new(record, @mapping)
        end

        # Public: Iterate through all Salesforce records of this type.
        #
        # Yields a series of Restforce::DB::Instances::Salesforce instances.
        # Returns nothing.
        def each
          DB.client.query("select #{lookups} from #{@record_type}").each do |record|
            yield Instances::Salesforce.new(record, @mapping)
          end
        end

        private

        # Internal: Get a String of values to look up when the record is
        # fetched from Salesforce. Includes all configured mappings and a
        # handful of attributes for internal use.
        #
        # Returns a String.
        def lookups
          (Instances::Salesforce::INTERNAL_ATTRIBUTES + @mapping.salesforce_fields).join(", ")
        end

      end

    end

  end

end
