module Restforce

  module DB

    module Instances

      class Base

        attr_reader :record

        def initialize(record, mappings = {})
          @record = record
          @mappings = mappings
        end

        def update!(attributes)
          record.update!(attributes)
        end

        def copy!(record)
          update! attributes_from(record.attributes)
        end

        def attributes
          @mappings.keys.each_with_object({}) do |attribute, attributes|
            attributes[attribute] = record.send(attribute)
          end
        end

        private

        def attributes_from(hash)
          @mappings.each_with_object({}) do |(attribute, mapping), attributes|
            attributes[attribute] = hash[mapping]
          end
        end

      end

    end

  end

end
