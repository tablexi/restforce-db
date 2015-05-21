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
          from_attributes = FieldProcessor.new.process(@record_type, from_record.attributes, :create)
          record_id = DB.client.create!(@record_type, from_attributes)

          from_record.update!(@mapping.lookup_column => record_id).after_sync

          find(record_id)
        end

        # Public: Find the first Salesforce record which meets the passed
        # conditions.
        #
        # conditions - One or more String query conditions
        #
        # Returns nil or a Restforce::DB::Instances::Salesforce instance.
        def first(*conditions)
          record = DB.client.query(query(conditions)).first
          return unless record

          Instances::Salesforce.new(@record_type, record, @mapping)
        end

        # Public: Find the Salesforce record corresponding to the passed id.
        #
        # id - The id of the record in Salesforce.
        #
        # Returns nil or a Restforce::DB::Instances::Salesforce instance.
        def find(id)
          first("Id = '#{id}'")
        end

        # Public: Get a collection of all Salesforce records of this type which
        # match the passed criteria.
        #
        # options - A Hash of options which should be applied to the set of
        #           fetched records. Allowed options are:
        #           :before     - A Time object defining the most recent update
        #                         timestamp for which records should be
        #                         returned.
        #           :after      - A Time object defining the least recent update
        #                         timestamp for which records should be
        #                         returned.
        #           :conditions - An Array of conditions to append to the lookup
        #                         query.
        #
        # Returns an Array of Restforce::DB::Instances::Salesforce instances.
        def all(options = {})
          constraints = [
            ("SystemModstamp < #{options[:before].utc.iso8601}" if options[:before]),
            ("SystemModstamp >= #{options[:after].utc.iso8601}" if options[:after]),
            *options[:conditions],
          ]

          DB.client.query(query(*constraints)).map do |record|
            Instances::Salesforce.new(@record_type, record, @mapping)
          end
        end

        private

        # Internal: Get a String of values to look up when the record is
        # fetched from Salesforce. Includes all configured mappings and a
        # handful of attributes for internal use.
        #
        # Returns a String.
        def lookups
          (Instances::Salesforce::INTERNAL_ATTRIBUTES + @mapping.salesforce_fields).uniq.join(", ")
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

        # Internal: Get a query String, given an Array of existing conditions.
        #
        # conditions - An Array of conditions to append to the query.
        #
        # Returns a String.
        def query(*conditions)
          filters = (conditions + @mapping.conditions).compact.join(" and ")
          filters = " where #{filters}" unless filters.empty?

          "select #{lookups} from #{@record_type}#{filters}"
        end

      end

    end

  end

end
