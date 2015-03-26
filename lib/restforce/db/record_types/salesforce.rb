module Restforce

  module DB

    module RecordTypes

      # Restforce::DB::RecordTypes::Salesforce serves as a wrapper for a single
      # Salesforce object class, allowing for standard record lookups and
      # attribute mappings.
      class Salesforce < Base

        # Public: Create an instance of this Salesforce model for the passed
        # database record.
        #
        # from_record - A Restforce::DB::Instances::ActiveRecord instance.
        #
        # Returns a Restforce::DB::Instances::Salesforce instance.
        # Raises on any error from Salesforce.
        def create!(from_record)
          attributes = @mapping.convert(@record_type, from_record.attributes)
          record_id = DB.client.create!(@record_type, attributes)

          from_record.update!(salesforce_id: record_id).after_sync

          find(record_id)
        end

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

          Instances::Salesforce.new(@record_type, record, @mapping)
        end

        # Public: Iterate through all Salesforce records of this type.
        #
        # options - A Hash of options which should be applied to the set of
        #           fetched records. Allowed options are:
        #           :before - A Time object defining the most recent update
        #                     timestamp for which records should be returned.
        #           :after  - A Time object defining the least recent update
        #                     timestamp for which records should be returned.
        #
        # Yields a series of Restforce::DB::Instances::Salesforce instances.
        # Returns nothing.
        def each(options = {})
          constraints = [
            ("SystemModstamp <= #{options[:before].utc.iso8601}" if options[:before]),
            ("SystemModstamp > #{options[:after].utc.iso8601}" if options[:after]),
          ].compact.join(" and ")
          constraints = " where #{constraints}" unless constraints.empty?

          query = "select #{lookups} from #{@record_type}#{constraints}"

          DB.client.query(query).each do |record|
            yield Instances::Salesforce.new(@record_type, record, @mapping)
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

        # Internal: Has this database record already been linked to a Salesforce
        # record?
        #
        # record - A Restforce::DB::Instances::Salesforce instance.
        #
        # Returns a Boolean.
        def synced?(record)
          record.synced?
        end

      end

    end

  end

end
