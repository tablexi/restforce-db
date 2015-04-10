module Restforce

  module DB

    module Associations

      # Restforce::DB::Associations::BelongsTo defines a relationship in which
      # a Salesforce ID on the named database association exists on this
      # Mapping's Salesforce record.
      class BelongsTo < Base

        # Public: Construct a database record from the Salesforce records
        # associated with the supplied parent Salesforce record.
        #
        # database_record   - An instance of an ActiveRecord::Base subclass.
        # salesforce_record - A Hashie::Mash representing a Salesforce object.
        #
        # Returns the constructed association record.
        def build(database_record, salesforce_record)
          lookups = {}

          attributes = Registry[target_class(database_record)].inject({}) do |hash, mapping|
            lookup_id = salesforce_record[lookup_field(mapping, database_record)]

            lookups[mapping.lookup_column] = lookup_id
            hash.merge(attributes_for(mapping, lookup_id))
          end

          associated = association_scope(database_record).find_by(lookups)
          associated ||= database_record.association(name).build(lookups)

          associated.assign_attributes(attributes)
          associated
        end

        private

        # Internal: Get a database-ready Hash of attributes from the Salesforce
        # record identified by the passed lookup ID.
        #
        # mapping   - A Restforce::DB::Mapping.
        # lookup_id - A Lookup ID for the Salesforce record type in the Mapping.
        #
        # Returns a Hash.
        def attributes_for(mapping, lookup_id)
          salesforce_instance = mapping.salesforce_record_type.find(lookup_id)
          mapping.convert(mapping.database_model, salesforce_instance.attributes)
        end

      end

    end

  end

end
