module Restforce

  module DB

    module Models

      class Base

        def initialize(model, mappings = {})
          @model = model
          @mappings = mappings
        end

        def map(mappings)
          @mappings.merge!(mappings)
        end

        def find(_)
          raise NotImplementedError
        end

      end

    end

  end

end
