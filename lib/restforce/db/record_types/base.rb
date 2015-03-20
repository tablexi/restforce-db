module Restforce

  module DB

    module RecordTypes

      # Restforce::DB::RecordTypes::Base defines common behavior for the other
      # models defined in the Restforce::DB::RecordTypes namespace.
      class Base

        # Public: Initialize a new Restforce::DB::RecordTypes::Base.
        #
        # record_type - The name or class of the system record type.
        # mapping     - An instance of Restforce::DB::Mapping.
        def initialize(record_type, mapping = Mapping.new)
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
            record = find(from_record.id)
            record.copy!(from_record)

            record
          else
            create!(from_record)
          end
        end

      end

    end

  end

end
