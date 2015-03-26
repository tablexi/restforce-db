module Restforce

  module DB

    module RecordTypes

      # Restforce::DB::RecordTypes::Base defines common behavior for the other
      # models defined in the Restforce::DB::RecordTypes namespace.
      class Base

        # Public: Initialize a new Restforce::DB::RecordTypes::Base.
        #
        # record_type - The name or class of the system record type.
        # mapping     - A Restforce::DB::Mapping.
        def initialize(record_type, mapping = nil)
          @record_type = record_type
          @mapping = mapping
        end

        # Public: Synchronize the passed record to the record type defined by
        # this class.
        #
        # from_record - A Restforce::DB::Instances::Base instance.
        #
        # Returns a Restforce::DB::Instances::Base instance.
        # Raises on any validation or external error.
        def sync!(from_record)
          if synced?(from_record)
            update!(from_record)
          elsif @mapping.root?
            create!(from_record)
          end
        end

        # Public: Update an existing record of this record type with the
        # attributes from the passed record. Only applies changes if from_record
        # has been more recently updated than the last record synchronization.
        #
        # from_record - A Restforce::DB::Instances::Base instance.
        #
        # Returns a Restforce::DB::Instances::Base instance.
        # Raises on any validation or external error.
        def update!(from_record)
          record = find(from_record.id)
          return record if from_record.last_update < record.last_synchronize

          record.copy!(from_record)
        end

      end

    end

  end

end
