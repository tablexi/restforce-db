module Restforce

  module DB

    # Restforce::DB::Model is a helper module which attaches some special
    # DSL-style methods to an ActiveRecord class, allowing for easier mapping
    # of the ActiveRecord class to an object type in Salesforce.
    module Model

      # :nodoc:
      def self.included(base)
        base.extend(ClassMethods)
      end

      # :nodoc:
      module ClassMethods

        # Public: Initializes a Restforce::DB::RecordType defining this model's
        # relationship to a Salesforce object type.
        #
        # salesforce_model - A String name of an object type in Salesforce.
        # mappings         - A Hash of mappings between database columns and
        #                    fields in Salesforce.
        #
        # Returns a Restforce::DB::RecordType.
        def map_to(salesforce_model, **mappings)
          RecordType.new(
            self,
            salesforce_model,
            mappings,
          )
        end

        # Public: Append the passed mappings to this model.
        #
        # mappings - A Hash of database column names mapped to Salesforce
        #            fields.
        #
        # Returns nothing.
        def add_mappings(mappings)
          RecordType[self].add_mappings(mappings)
        end

      end

    end

  end

end
