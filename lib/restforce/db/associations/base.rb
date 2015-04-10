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
          @name = name
          @lookup = through
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
          []
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
          inverse = inverse_association_name(database_record)
          mapping.associations.detect { |a| a.name == inverse }.lookup
        end

        # Internal: Get the class of the inverse ActiveRecord association.
        #
        # database_record - An instance of an ActiveRecord::Base subclass.
        #
        # Returns a Class.
        def target_class(database_record)
          reflection(database_record).klass
        end

        # Internal: Get the name of the inverse association which corresponds
        # to this one.
        #
        # database_record - An instance of an ActiveRecord::Base subclass.
        #
        # Returns a Symbol.
        def inverse_association_name(database_record)
          reflection(database_record).send(:inverse_name)
        end

        # Internal: Get an AssociationReflection for this association on the
        # passed database record.
        #
        # database_record - An instance of an ActiveRecord::Base subclass.
        #
        # Returns an ActiveRecord::AssociationReflection.
        def reflection(database_record)
          database_record.class.reflect_on_association(name)
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

      end

    end

  end

end
