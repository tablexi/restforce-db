module Restforce

  module DB

    module Instances

      # Internal: Restforce::DB::Instances::Base defines common behavior for the
      # other models defined in the Restforce::DB::Instances namespace.
      class Base

        attr_reader :record

        # Public: Initialize a new Restforce::DB::Instances::Base instance.
        #
        # record   - The Salesforce or database record to manage.
        # mappings - A Hash of mappings between database columns and Salesforce
        #            fields.
        def initialize(record, mappings = {})
          @record = record
          @mappings = mappings
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
        #          attributes corresponding to the configured mapping values for
        #          this instance.
        #
        # Returns a truthy value.
        # Raises if the update fails for any reason.
        def copy!(record)
          update! attributes_from(record.attributes)
        end

        # Public: Get a Hash mapping the configured attributes names to their
        # values for this instance.
        #
        # Returns a Hash.
        def attributes
          @mappings.keys.each_with_object({}) do |attribute, attributes|
            attributes[attribute] = record.send(attribute)
          end
        end

        private

        # Internal: Get a Hash of attributes compatible with this instance by
        # applying the configured mappings for this instance to "decode" a
        # set of attributes from another instance.
        #
        # hash - The Hash of mapped attributes.
        #
        # Returns a Hash.
        def attributes_from(hash)
          @mappings.each_with_object({}) do |(attribute, mapping), attributes|
            attributes[attribute] = hash[mapping]
          end
        end

      end

    end

  end

end
