module Restforce

  module DB

    module Associations

      # Restforce::DB::Associations::HasMany defines a relationship in which
      # potentially several Salesforce records maintain a reference to the
      # Salesforce record on the current Mapping.
      class HasMany < Base

        # Public: Construct a database record for each Salesforce record
        #
        # database_record   - An instance of an ActiveRecord::Base subclass.
        # salesforce_record - A Hashie::Mash representing a Salesforce object.
        #
        # Returns the constructed association records.
        def build(database_record, salesforce_record)
          target = target_mapping(database_record)
          lookup_id = "#{lookup_field(target, database_record)} = '#{salesforce_record.Id}'"

          records = []
          target.salesforce_record_type.each(conditions: lookup_id) do |instance|
            records << construct_for(database_record, instance)
          end

          records
        end

        private

        # Internal: Identify the inverse mapping for this relationship by
        # looking it up through the target association.
        #
        # database_record - An instance of an ActiveRecord::Base subclass.
        #
        # Returns a Restforce::DB::Mapping.
        def target_mapping(database_record)
          inverse = inverse_association_name(database_record)
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
          associated
        end

      end

    end

  end

end
