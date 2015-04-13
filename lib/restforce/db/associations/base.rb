module Restforce

  module DB

    module Associations

      # Restforce::DB::Associations::Base defines an association between two
      # mappings in the Registry.
      class Base

        attr_reader :name, :lookup

        # Public: Initialize a new Restforce::DB::Associations::Base.
        #
        # name    - The name of the ActiveRecord association to construct.
        # through - The name of the lookup field on the Salesforce record.
        def initialize(name, through: nil)
          @name = name.to_sym
          @lookup = through.is_a?(Array) ? through.map(&:to_s) : through.to_s
        end

        # Public: Build a record or series of records for the association
        # defined by this class. Must be overridden in subclasses.
        #
        # Raises a NotImplementedError.
        def build(_database_record, _salesforce_record)
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
          base_class = instance.mapping.database_model
          reflection = base_class.reflect_on_association(name)
          association_id = associated_salesforce_id(instance)

          return false unless association_id
          reflection.klass.exists?(
            mapping_for(reflection).lookup_column => association_id,
          )
        end

        private

        # Internal: Get the appropriate Salesforce Lookup ID field for the
        # passed mapping.
        #
        # mapping         - A Restforce::DB::Mapping.
        # database_record - An instance of an ActiveRecord::Base subclass.
        #
        # Returns a String.
        def lookup_field(mapping, database_record)
          inverse = inverse_association_name(target_reflection(database_record))
          mapping.associations.detect { |a| a.name == inverse }.lookup
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
        def mapping_for(reflection)
          inverse = inverse_association_name(reflection)
          Registry[reflection.klass].detect do |mapping|
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
          inverse = reflection.send(:inverse_name)
          Registry[reflection.klass].detect do |mapping|
            association = mapping.associations.detect { |a| a.name == inverse }
            break association if association
          end
        end

        # Internal: Get an ActiveRecord::Relation scope for the passed record's
        # association.
        #
        # database_record - An instance of an ActiveRecord::Base subclass.
        #
        # Returns an ActiveRecord scope.
        def association_scope(database_record)
          database_record.association(name).scope
        end

        # Internal: Get the Salesforce ID belonging to the associated record
        # for a supplied instance. Must be implemented per-association.
        #
        # instance - A Restforce::DB::Instances::Base
        #
        # Returns a String.
        def associated_salesforce_id(_instance)
          raise NotImplementedError
        end

      end

    end

  end

end
