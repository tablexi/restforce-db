module Restforce

  module DB

    module RecordTypes

      # Internal: Restforce::DB::RecordTypes::Base defines common behavior for
      # the other models defined in the Restforce::DB::RecordTypes namespace.
      class Base

        # Public: Initialize a new Restforce::DB::RecordTypes::Base.
        #
        # model   - The name or class of the model.
        # mapping - An instance of Restforce::DB::Mapping.
        def initialize(model, mapping = Mapping.new)
          @model = model
          @mapping = mapping
        end

      end

    end

  end

end
