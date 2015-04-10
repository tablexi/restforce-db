module Restforce

  module DB

    # Restforce::DB::DSL defines a syntax through which a Mapping may be
    # configured between a database model and an object type in Salesforce.
    class DSL

      attr_reader :mapping

      # Public: Initialize a Restforce::DB::DSL.
      #
      # database_model   - An ActiveRecord::Base subclass.
      # salesforce_model - A String Salesforce object name.
      # strategy_name    - A Symbol initialization strategy name.
      # options          - A Hash of options to pass to the Strategy object.
      #
      # Returns nothing.
      def initialize(database_model, salesforce_model, strategy_name, options = {})
        strategy = Strategy.for(strategy_name, options)
        @mapping = Mapping.new(database_model, salesforce_model, strategy)
        Registry << @mapping
      end

      # Public: Define a set of conditions which should be used to filter the
      # Salesforce record lookups for this mapping.
      #
      # conditions - An Array of String query conditions.
      #
      # Returns nothing.
      def where(*conditions)
        @mapping.conditions = conditions
      end

      # Public: Define a relationship in which the current mapping contains the
      # lookup ID for another mapping.
      #
      # association - The name of the ActiveRecord association.
      # through     - A String or Array of Strings representing the Lookup IDs.
      #
      # Returns nothing.
      def belongs_to(association, through:)
        @mapping.associations << Associations::BelongsTo.new(
          association,
          through: through,
        )
      end

      # Public: Define a relationship in which the current mapping is referenced
      # by one object through a lookup ID on another mapping.
      #
      # association - The name of the ActiveRecord association.
      # through     - A String representing the Lookup ID.
      #
      # Returns nothing.
      def has_one(association, through:) # rubocop:disable PredicateName
        @mapping.associations << Associations::HasOne.new(
          association,
          through: through,
        )
      end

      # Public: Define a set of fields which should be synchronized between the
      # database record and Salesforce.
      #
      # fields - A Hash, with keys corresponding to attributes of the database
      #          record, and values corresponding to field names in Salesforce.
      #
      # Returns nothing.
      def maps(fields)
        @mapping.fields = fields
      end

    end

  end

end
