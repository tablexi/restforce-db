module Restforce

  module DB

    # Restforce::DB::Registry is responsible for keeping track of all mappings
    # established in the system.
    class Registry

      extend Enumerable

      # Public: Get the Restforce::DB::Mapping entry for the specified model.
      #
      # model - A String or Class.
      #
      # Returns a Restforce::DB::Mapping.
      def self.[](model)
        @collection[model]
      end

      # Public: Iterate through all registered Restforce::DB::Mappings.
      #
      # Yields one Mapping for each database-to-Salesforce mapping.
      # Returns nothing.
      def self.each
        @collection.each do |model, mappings|
          # Since each mapping is inserted twice, we ignore the half which
          # were inserted via Salesforce model names.
          next unless model.is_a?(Class)

          mappings.each do |mapping|
            yield mapping
          end
        end
      end

      # Public: Add a mapping to the overarching Mapping collection. Appends
      # the mapping to the collection for both its database and salesforce
      # object types.
      #
      # mapping - A Restforce::DB::Mapping.
      #
      # Returns nothing.
      def self.<<(mapping)
        [mapping.database_model, mapping.salesforce_model].each do |model|
          @collection[model] << mapping
        end
      end

      # Public: Clear out any existing registered mappings.
      #
      # Returns nothing.
      def self.clean!
        @collection = Hash.new { |h, k| h[k] = [] }
      end

      clean!

    end

  end

end
