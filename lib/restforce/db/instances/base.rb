module Restforce

  module DB

    module Instances

      # Restforce::DB::Instances::Base defines common behavior for the other
      # models defined in the Restforce::DB::Instances namespace.
      class Base

        attr_reader :record

        # Public: Initialize a new Restforce::DB::Instances::Base instance.
        #
        # record  - The Salesforce or database record to manage.
        # mapping - An instance of Restforce::DB::Mapping.
        def initialize(record, mapping = Mapping.new)
          @record = record
          @mapping = mapping
        end

        # Public: Update the instance with the passed attributes.
        #
        # attributes - A Hash mapping attribute names to values.
        #
        # Returns a truthy value.
        # Raises if the update fails for any reason.
        def update!(attributes)
          record.update!(attributes)
        end

        # Public: Update the instance with attributes copied from the passed
        # record.
        #
        # record - An object responding to `#attributes`. Must return a Hash of
        #          attributes corresponding to the configured mappings for this
        #          instance.
        #
        # Returns a truthy value.
        # Raises if the update fails for any reason.
        def copy!(from_record)
          update! @mapping.convert(conversion, from_record.attributes)
        end

        # Public: Get a Hash mapping the configured attributes names to their
        # values for this instance.
        #
        # Returns a Hash.
        def attributes
          @mapping.attributes(conversion) do |attribute|
            record.send(attribute)
          end
        end

      end

    end

  end

end
