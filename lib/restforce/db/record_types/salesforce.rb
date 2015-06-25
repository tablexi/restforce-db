module Restforce

  module DB

    module RecordTypes

      # Restforce::DB::RecordTypes::Salesforce serves as a wrapper for a single
      # Salesforce object class, allowing for standard record lookups and
      # attribute mappings.
      class Salesforce < Base

        ALREADY_EXISTS_MESSAGE = /INVALID_FIELD_FOR_INSERT_UPDATE|DUPLICATE_VALUE/.freeze

        # Public: Create an instance of this Salesforce model for the passed
        # database record.
        #
        # from_record - A Restforce::DB::Instances::ActiveRecord instance.
        #
        # Returns a Restforce::DB::Instances::Salesforce instance.
        # Raises on any error from Salesforce.
        def create!(from_record)
          record_id = upsert!(from_record)

          # NOTE: #upsert! returns a String Salesforce ID when a record is
          # created, and returns `true` when an existing record was found.
          if record_id.is_a?(String)
            from_record.update!(@mapping.lookup_column => record_id).after_sync
            find(record_id)
          else
            instance = first("SynchronizationId__c = '#{from_record.uuid}'")
            from_record.update!(@mapping.lookup_column => instance.id).after_sync
            instance
          end
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

        # Internal: Get a list of fields to look up when the record is
        # fetched from Salesforce. Includes all configured mappings and a
        # handful of attributes for internal use.
        #
        # Returns an Array of Strings.
        def lookups
          FieldProcessor.new.available_fields(
            @record_type,
            (Instances::Salesforce::INTERNAL_ATTRIBUTES + @mapping.salesforce_fields).uniq,
          )
        end

        # Internal: Attempt to create a record in Salesforce from the passed
        # database instance.
        #
        # Returns a String or Boolean.
        def upsert!(from_record)
          from_attributes = FieldProcessor.new.process(
            @record_type,
            from_record.attributes,
            :create,
          )

          DB.client.upsert!(
            @record_type,
            "SynchronizationId__c",
            from_attributes.merge("SynchronizationId__c" => from_record.uuid),
          )
        rescue Faraday::Error::ClientError => e
          # If the error is complaining about attempting to update create-only
          # fields, we've confirmed that the record already exists, and can
          # safely resolve our object creation.
          if e.message =~ ALREADY_EXISTS_MESSAGE
            true
          else
            raise e
          end
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

          "select #{lookups.join(', ')} from #{@record_type}#{filters}"
        end

      end

    end

  end

end
