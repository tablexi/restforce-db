module Restforce

  module DB

    # Restforce::DB::RunnerCache serves as a means of caching the collections of
    # recently-updated database and Salesforce instances for passed mappings.
    # The general goal is to avoid making repetitive Salesforce API calls or
    # database queries, and ensure a consistent list of objects during a
    # synchronization run.
    class RunnerCache

      # Public: Initialize a new Restforce::DB::RunnerCache.
      def initialize
        reset
      end

      # Public: Iterate through the recently-updated instances of the specified
      # type for the passed mapping. Memoizes the records if the collection has
      # not previously been cached.
      #
      # mapping     - A Restforce::DB::Mapping.
      # record_type - A Symbol naming a mapping record type. Valid values are
      #               :salesforce_record_type or :database_record_type.
      # options     - A Hash of options to pass to `each` (optional).
      #
      # Returns an Array of Restforce::DB::Instances::Base.
      def collection(mapping, record_type, options = {})
        return cached_value(mapping, record_type) if cached?(mapping, record_type)
        cache(mapping, record_type, mapping.send(record_type).all(options))
      end

      # Public: Reset the cache. Should be invoked between runs to ensure that
      # new options are respected.
      #
      # Returns nothing.
      def reset
        @cache = Hash.new { |h, k| h[k] = {} }
      end

      private

      # Internal: Store the supplied value in the cache for the passed mapping
      # and record type.
      #
      # mapping     - A Restforce::DB::Mapping.
      # record_type - A Symbol naming a mapping record type. Valid values are
      #               :salesforce_record_type or :database_record_type.
      #
      # Returns the cached value.
      def cache(mapping, record_type, value)
        @cache[record_type][key_for(mapping)] = value
      end

      # Internal: Get the cached collection for the passed mapping and record
      # type.
      #
      # mapping     - A Restforce::DB::Mapping.
      # record_type - A Symbol naming a mapping record type. Valid values are
      #               :salesforce_record_type or :database_record_type.
      #
      # Returns nil or an Array.
      def cached_value(mapping, record_type)
        @cache[record_type][key_for(mapping)]
      end

      # Internal: Have we cached a collection for the passed mapping and record
      # type?
      #
      # mapping     - A Restforce::DB::Mapping.
      # record_type - A Symbol naming a mapping record type. Valid values are
      #               :salesforce_record_type or :database_record_type.
      #
      # Returns a Boolean.
      def cached?(mapping, record_type)
        !cached_value(mapping, record_type).nil?
      end

      # Internal: Get a unique key with enough information to look up the passed
      # mapping in the cache. Scopes the mapping by its current list of
      # conditions.
      #
      # mapping - A Restforce::DB::Mapping.
      #
      # Returns an Object.
      def key_for(mapping)
        [mapping, mapping.conditions]
      end

    end

  end

end
