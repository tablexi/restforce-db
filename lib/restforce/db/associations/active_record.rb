module Restforce

  module DB

    module Associations

      # Restforce::DB::Associations::ActiveRecord is a utility class which
      # encapsulates the logic for creating/populating a one-to-one association
      #
      class ActiveRecord

        attr_reader :associated

        # Public: Initialize a new Restforce::DB::Associations::ActiveRecord.
        #
        # record      - The base ActiveRecord::Base instance for which the
        #               association should be built.
        # association - The name of the association which should be built.
        def initialize(record, association)
          @record = record
          @associated = record.association(association).build
        end

        # Public: Build the associated record from the attributes found on the
        # passed Salesforce record's lookups.
        #
        # from_record - A Hashie::Mash representing a base Salesforce record.
        #
        # Returns the constructed associated record.
        def build(from_record)
          Registry[associated.class].each do |mapping|
            lookup_id = from_record[mapping.through]
            apply(mapping, lookup_id)
          end

          associated
        end

        private

        # Internal: Assemble the associated record, using the data from the
        # Salesforce record corresponding to a specific lookup ID.
        #
        # TODO: With some refactoring, this should be possible to handle as a
        # recursive call to the configured Mapping's database record type. Right
        # now, nested associations are unhandled.
        #
        # mapping   - A Restforce::DB::Mapping.
        # lookup_id - A Salesforce ID corresponding to the record type in the
        #             passed Mapping.
        #
        # Returns nothing.
        def apply(mapping, lookup_id)
          return if lookup_id.nil?

          salesforce_instance = mapping.salesforce_record_type.find(lookup_id)
          attributes = mapping.convert(associated.class, salesforce_instance.attributes)

          associated.assign_attributes(attributes.merge(mapping.lookup_column => lookup_id))
        end

      end

    end

  end

end
