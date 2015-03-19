module Restforce

  module DB

    module RecordTypes

      # Restforce::DB::RecordTypes::ActiveRecord serves as a wrapper for a
      # single ActiveRecord::Base-compatible class, allowing for standard record
      # lookups and attribute mappings.
      class ActiveRecord < Base

        # Public: Synchronize the passed Salesforce record with the database.
        #
        # from_record - A Restforce::DB::Instances::Salesforce instance.
        #
        # Returns a Restforce::DB::Instances::ActiveRecord instance.
        # Raises on any validation or database error.
        def sync!(from_record)
          if @record_type.exists?(salesforce_id: from_record.id)
            record = find(from_record.id)
            record.copy!(from_record)

            record
          else
            create!(from_record)
          end
        end

        # Public: Create an instance of this ActiveRecord model for the passed
        # Salesforce instance.
        #
        # from_record - A Restforce::DB::Instances::Salesforce instance.
        #
        # Returns a Restforce::DB::Instances::ActiveRecord instance.
        # Raises on any validation or database error.
        def create!(from_record)
          attributes = @mapping.convert(:database, from_record.attributes)
          record = @record_type.create!(
            attributes.merge(salesforce_id: from_record.id),
          )

          Instances::ActiveRecord.new(record, @mapping)
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

          Instances::ActiveRecord.new(record, @mapping)
        end

      end

    end

  end

end
