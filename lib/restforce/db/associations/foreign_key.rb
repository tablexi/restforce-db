module Restforce

  module DB

    module Associations

      # Restforce::DB::Associations::ForeignKey defines a relationship in which
      # the Salesforce IDs for any associated record(s) are present on a foreign
      # record type.
      class ForeignKey < Base

        # Public: Get a list of fields which should be included in the
        # Salesforce record's lookups for any mapping including this
        # association.
        #
        # Returns a list of Salesforce fields this record should return.
        def fields
          []
        end

        private

        # Internal: Identify the inverse mapping for this relationship by
        # looking it up through the target association.
        #
        # database_record - An instance of an ActiveRecord::Base subclass.
        #
        # Returns a Restforce::DB::Mapping.
        def target_mapping(database_record)
          inverse = inverse_association_name(target_reflection(database_record))
          Registry[target_class(database_record)].detect do |mapping|
            mapping.associations.any? { |a| a.name == inverse }
          end
        end

        # Internal: Construct a single associated record from the supplied
        # Salesforce instance.
        #
        # database_record     - An instance of an ActiveRecord::Base subclass.
        # salesforce_instance - A Restforce::DB::Instances::Salesforce.
        #
        # Returns the constructed object.
        def construct_for(database_record, salesforce_instance)
          mapping = salesforce_instance.mapping
          lookups = { mapping.lookup_column => salesforce_instance.id }
          associated = association_scope(database_record).find_by(lookups)
          associated ||= database_record.association(name).build(lookups)

          attributes = mapping.convert(
            associated.class,
            salesforce_instance.attributes,
          )

          associated.assign_attributes(attributes)
          [associated, *nested_records(database_record, associated, salesforce_instance)]
        end

        # Internal: Get the Salesforce ID belonging to the associated record
        # for a supplied instance. Must be implemented per-association.
        #
        # instance - A Restforce::DB::Instances::Base
        #
        # Returns a String.
        def associated_salesforce_id(instance)
          query = "#{lookup} = '#{instance.id}'"

          reflection = instance.mapping.database_model.reflect_on_association(name)
          inverse_mapping = mapping_for(reflection)

          salesforce_instance = inverse_mapping.salesforce_record_type.first(query)
          salesforce_instance.id if salesforce_instance
        end

      end

    end

  end

end
