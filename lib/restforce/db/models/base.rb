module Restforce

  module DB

    module Models

      # Internal: Restforce::DB::Models::Base defines common behavior for the
      # other models defined in the Restforce::DB::Models namespace.
      class Base

        # Public: Initialize a new Restforce::DB::Models::Base.
        #
        # model    - The name or class of the model.
        # mappings - A Hash of mappings between database columns and Salesforce
        #            fields.
        def initialize(model, mappings = {})
          @model = model
          @mappings = mappings
        end

        # Public: Append the passed database-to-Salesforce mappings to the
        # currently configured mappings.
        #
        # Returns a Hash.
        def map(mappings)
          @mappings.merge!(mappings)
        end

      end

    end

  end

end
