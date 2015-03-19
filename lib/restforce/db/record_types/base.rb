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

      end

    end

  end

end
