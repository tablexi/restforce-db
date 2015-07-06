module Restforce

  module DB

    module Associations

      # Restforce::DB::Associations::Base defines an association between two
      # mappings in the Registry.
      class Base

        attr_reader :name, :lookup, :cache

        # Public: Initialize a new Restforce::DB::Associations::Base.
        #
        # name    - The name of the ActiveRecord association to construct.
        # through - The name of the lookup field on the Salesforce record.
        # build   - A Boolean indicating whether or not the association chain
        #           should be built out for new records.
        def initialize(name, through: nil, build: true)
          @name = name.to_sym
          @lookup = through.is_a?(Array) ? through.map(&:to_s) : through.to_s
          @build = build
        end

        # Public: Build a record or series of records for the association
        # defined by this class. Must be overridden in subclasses.
        #
        # Raises a NotImplementedError.
        def build(_database_record, _salesforce_record, _cache)
          raise NotImplementedError
        end

        # Public: Get a list of fields which should be included in the
        # Salesforce record's lookups for any mapping including this
        # association.
        #
        # Returns a list of Salesforce fields this record should return.
        def fields
          [*lookup]
        end

        # Public: Has a record for this association already been synchronized
        # for the supplied instance?
        #
        # instance - A Restforce::DB::Instances::Base.
        #
        # Returns a Boolean.
        def synced_for?(instance)
          association_id = associated_salesforce_id(instance)
          return false unless association_id

          base_class = instance.mapping.database_model
          reflection = base_class.reflect_on_association(name)

          mappings_for(reflection).any? do |mapping|
            reflection.klass.exists?(mapping.lookup_column => association_id)
          end
        end

        private

        # Internal: Should records for this association be synchronized between
        # the two systems when a new record is added for the base mapping?
        #
        # Returns a Boolean.
        def build?
          @build
        end

        # Internal: Get the appropriate Salesforce Lookup ID field for the
        # passed mapping.
        #
        # mapping    - A Restforce::DB::Mapping.
        # reflection - An ActiveRecord::AssociationReflection.
        #
        # Returns a String or nil.
        def lookup_field(mapping, reflection)
          inverse = inverse_association_name(reflection)
          association = mapping.associations.detect { |a| a.name == inverse }
          return unless association

          if lookup.is_a?(Array)
            association.lookup
          else
            lookup
          end
        end

        # Internal: Get a list of all newly-constructed records based on this
        # association, for a set of lookups.
        #
        # database_record - An instance of an ActiveRecord::Base subclass.
        # lookups         - A Hash mapping database columns to Salesforce IDs.
        # attributes      - A Hash of attributes to assign to the new record.
        #
        # Yields the new database record if one is built.
        # Returns an Array containing all newly-constructed records.
        def constructed_records(database_record, lookups, attributes)
          associated = cache.find(target_class(database_record), lookups)

          # If the association record already exists, we don't need to build out
          # associations any further.
          if associated
            database_record.association(name).send(construction_method, associated)
            return []
          end

          associated = database_record.association(name).build(lookups)
          cache << associated

          associated.assign_attributes(attributes)

          nested = yield associated if block_given?

          [associated, *nested]
        end

        # Internal: Get the method by which an associated record should be
        # assigned to this record. Defaults to :writer, which overwrites the
        # existing association, if one exists.
        #
        # Returns a Symbol.
        def construction_method
          :writer
        end

        # Internal: Get the class of the inverse ActiveRecord association.
        #
        # database_record - An instance of an ActiveRecord::Base subclass.
        #
        # Returns a Class.
        def target_class(database_record)
          target_reflection(database_record).klass
        end

        # Internal: Get an AssociationReflection for this association on the
        # passed database record.
        #
        # database_record - An instance of an ActiveRecord::Base subclass.
        #
        # Returns an ActiveRecord::AssociationReflection.
        def target_reflection(database_record)
          database_record.class.reflect_on_association(name)
        end

        # Internal: Get the name of the inverse association which corresponds
        # to this one.
        #
        # reflection - An ActiveRecord::AssociationReflection.
        #
        # Returns a Symbol.
        def inverse_association_name(reflection)
          reflection.send(:inverse_name)
        end

        # Internal: Get the first mapping which corresponds to an ActiveRecord
        # reflection.
        #
        # reflection - An ActiveRecord::AssociationReflection.
        #
        # Returns a Restforce::DB::Mapping.
        def mappings_for(reflection)
          inverse = inverse_association_name(reflection)
          Registry[reflection.klass].select do |mapping|
            mapping.associations.any? { |a| a.name == inverse }
          end
        end

        # Internal: Get the first association which corresponds to an
        # ActiveRecord reflection.
        #
        # reflection - An ActiveRecord::AssociationReflection.
        #
        # Returns a Restforce::DB::Associations::Base.
        def association_for(reflection)
          inverse = inverse_association_name(reflection)
          Registry[reflection.klass].detect do |mapping|
            association = mapping.associations.detect { |a| a.name == inverse }
            break association if association
          end
        end

        # Internal: Construct all associated records for the passed database
        # record, based on the mapping represented by the passed Salesforce
        # instance.
        #
        # parent_record       - The parent of the associated_record; an instance
        #                       of an ActiveRecord::Base subclass.
        # associated_record   - The child of the parent_record; an instance of
        #                       an ActiveRecord::Base subclass.
        # salesforce_instance - A Restforce::DB::Instances::Salesforce which
        #                       corresponds to the associated_record.
        #
        # Returns an Array of associated records.
        def nested_records(parent_record, database_record, salesforce_instance)
          # We need to identify _this_ association to prevent backtracking.
          inverse = inverse_association_name(target_reflection(parent_record))
          nested = salesforce_instance.mapping.associations.flat_map do |a|
            next if a.name == inverse
            a.build(database_record, salesforce_instance.record, cache)
          end

          nested.compact
        end

        # Internal: Get the Salesforce ID belonging to the associated record
        # for a supplied instance. Must be implemented per-association.
        #
        # instance - A Restforce::DB::Instances::Base.
        #
        # Returns a String.
        def associated_salesforce_id(_instance)
          raise NotImplementedError
        end

      end

    end

  end

end
