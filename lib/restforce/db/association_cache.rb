module Restforce

  module DB

    # Restforce::DB::AssociationCache stores a set of constructed database
    # association records, providing utilities to fetch unpersisted records
    # which match a specific set of Salesforce lookups.
    class AssociationCache

      attr_reader :cache

      # Public: Initialize a new Restforce::DB::AssociationCache.
      #
      # record - An instance of ActiveRecord::Base (optional).
      def initialize(record = nil)
        @cache = Hash.new { |h, k| h[k] = [] }
        self << record if record
      end

      # Public: Add a record to the cache.
      #
      # record - An instance of ActiveRecord::Base.
      #
      # Returns nothing.
      def <<(record)
        @cache[record.class] << record
      end

      # Public: Find an existing record with the given lookup values.
      #
      # database_model - A subclass of ActiveRecord::Base.
      # lookups        - A Hash mapping database columns to Salesforce IDs.
      #
      # Returns an instance of ActiveRecord::Base or nil.
      def find(database_model, lookups)
        record = @cache[database_model].detect do |cached|
          lookups.all? { |column, value| cached.send(column) == value }
        end

        return record if record

        record = database_model.find_by(lookups)
        self << record if record

        record
      end

    end

  end

end
