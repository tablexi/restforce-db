module Restforce

  module DB

    module RecordTypes

      # Restforce::DB::RecordTypes::ActiveRecord serves as a wrapper for a
      # single ActiveRecord::Base-compatible class, allowing for standard record
      # lookups and attribute mappings.
      class ActiveRecord < Base

        # Public: Create an instance of this ActiveRecord model for the passed
        # Salesforce instance.
        #
        # from_record - A Restforce::DB::Instances::Salesforce instance.
        #
        # Returns a Restforce::DB::Instances::ActiveRecord instance.
        # Raises on any validation or database error.
        def create!(from_record)
          attributes = @mapping.convert(@record_type, from_record.attributes)

          record = @record_type.create!(attributes.merge(salesforce_id: from_record.id))

          Instances::ActiveRecord.new(@record_type, record, @mapping).after_sync
        end

        # Public: Find the instance of this ActiveRecord model corresponding to
        # the passed salesforce_id.
        #
        # salesforce_id - The id of the record in Salesforce.
        #
        # Returns nil or a Restforce::DB::Instances::ActiveRecord instance.
        def find(id)
          record = @record_type.find_by(salesforce_id: id)
          return nil unless record

          Instances::ActiveRecord.new(@record_type, record, @mapping)
        end

        # Public: Iterate through all recently-updated ActiveRecord records of
        # this type.
        #
        # options - A Hash of options which should be applied to the set of
        #           fetched records. Allowed options are:
        #           :before - A Time object defining the most recent update
        #                     timestamp for which records should be returned.
        #           :after  - A Time object defining the least recent update
        #                     timestamp for which records should be returned.
        #
        # Yields a series of Restforce::DB::Instances::ActiveRecord instances.
        # Returns nothing.
        def each(options = {})
          scope = @record_type.where("updated_at > synchronized_at OR synchronized_at IS NULL")
          scope = scope.where("updated_at > ?", options[:after]) if options[:after]
          scope = scope.where("updated_at < ?", options[:before]) if options[:before]

          scope.find_each do |record|
            yield Instances::ActiveRecord.new(@record_type, record, @mapping)
          end
        end

        private

        # Internal: Has this Salesforce record already been linked to a database
        # record of this type?
        #
        # record - A Restforce::DB::Instances::Salesforce instance.
        #
        # Returns a Boolean.
        def synced?(record)
          @record_type.exists?(salesforce_id: record.id)
        end

      end

    end

  end

end
