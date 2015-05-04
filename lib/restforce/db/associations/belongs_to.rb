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
        # cache             - A Restforce::DB::AssociationCache (optional).
        #
        # Returns an Array of constructed association records.
        def build(database_record, salesforce_record, cache = AssociationCache.new(database_record))
          @cache = cache

          lookups = {}
          attributes = {}
          instances = []

          for_mappings(database_record) do |mapping, lookup|
            lookup_id = salesforce_record[lookup]
            lookups[mapping.lookup_column] = lookup_id
            instance = mapping.salesforce_record_type.find(lookup_id)

            # If any of the mappings are invalid, short-circuit the creation of
            # the associated record.
            return [] unless instance

            instances << instance
            attrs = mapping.convert(mapping.database_model, instance.attributes)
            attributes = attributes.merge(attrs)
          end

          constructed_records(database_record, lookups, attributes) do |associated|
            instances.flat_map { |i| nested_records(database_record, associated, i) }
          end
        ensure
          @cache = nil
        end

        # Public: Get a Hash of Lookup IDs for a specified database record,
        # based on the current record for this association.
        #
        # database_record - An instance of an ActiveRecord::Base subclass.
        #
        # Returns a Hash.
        def lookups(database_record)
          ids = {}

          for_mappings(database_record) do |mapping, lookup|
            associated = database_record.association(name).reader

            if associated
              # It's possible to define a belongs_to association in a Mapping
              # for what is actually a one-to-many association in ActiveRecord.
              associated = associated.first if associated.respond_to?(:first)
              ids[lookup] = associated.send(mapping.lookup_column)
            else
              ids[lookup] = nil
            end
          end

          ids
        end

        private

        # Internal: Iterate through all relevant mappings for the target
        # ActiveRecord class.
        #
        # database_record - An instance of an ActiveRecord::Base subclass.
        #
        # Yields the Restforce::DB::Mapping and the corresponding String lookup.
        # Returns nothing.
        def for_mappings(database_record)
          Registry[target_class(database_record)].each do |mapping|
            lookup = lookup_field(mapping, database_record)
            next unless lookup
            yield mapping, lookup
          end
        end

        # Internal: Get the Salesforce ID belonging to the associated record
        # for a supplied instance. Must be implemented per-association.
        #
        # instance - A Restforce::DB::Instances::Base.
        #
        # Returns a String.
        def associated_salesforce_id(instance)
          reflection = instance.mapping.database_model.reflect_on_association(name)
          inverse_association = association_for(reflection)

          salesforce_instance = instance.mapping.salesforce_record_type.find(instance.id)
          salesforce_instance.record[inverse_association.lookup] if salesforce_instance
        end

        # Internal: Get the appropriate Salesforce Lookup ID field for the
        # passed mapping.
        #
        # mapping         - A Restforce::DB::Mapping.
        # database_record - An instance of an ActiveRecord::Base subclass.
        #
        # Returns a String or nil.
        def lookup_field(mapping, database_record)
          inverse = inverse_association_name(target_reflection(database_record))
          association = mapping.associations.detect { |a| a.name == inverse }
          return unless association

          association.lookup
        end

      end

    end

  end

end
