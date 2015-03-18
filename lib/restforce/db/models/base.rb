module Restforce

  module DB

    module Models

      # Internal: Restforce::DB::Models::Base defines common behavior for the
      # other models defined in the Restforce::DB::Models namespace.
      class Base

        # Public: Initialize a new Restforce::DB::Models::Base.
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
