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
        def target_mappings(database_record)
          inverse = inverse_association_name(target_reflection(database_record))
          Registry[target_class(database_record)].select do |mapping|
            mapping.associations.any? { |a| a.name == inverse }
          end
        end

        # Internal: Construct a single associated record from the supplied
        # Salesforce instance.
        #
        # database_record     - An instance of an ActiveRecord::Base subclass.
        # salesforce_instance - A Restforce::DB::Instances::Salesforce.
        #
        # Returns an Array of constructed associated objects.
        def construct_for(database_record, salesforce_instance)
          mapping = salesforce_instance.mapping
          lookups = { mapping.lookup_column => salesforce_instance.id }

          attributes = mapping.convert(
            mapping.database_model,
            salesforce_instance.attributes,
          )

          constructed_records(database_record, lookups, attributes) do |associated|
            nested_records(database_record, associated, salesforce_instance)
          end
        end

        # Internal: Get the Salesforce ID belonging to the associated record
        # for a supplied instance. Must be implemented per-association.
        #
        # instance - A Restforce::DB::Instances::Base
        #
        # Returns a String.
        def associated_salesforce_id(instance)
          reflection = instance.mapping.database_model.reflect_on_association(name)

          mappings_for(reflection).detect do |inverse_mapping|
            query = "#{lookup_field(inverse_mapping, reflection)} = '#{instance.id}'"
            salesforce_instance = inverse_mapping.salesforce_record_type.first(query)
            break salesforce_instance.id if salesforce_instance
          end
        end

      end

    end

  end

end
