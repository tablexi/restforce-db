module Restforce

  module DB

    # Restforce::DB::TimestampCache serves to cache the timestamps of the most
    # recent known updates to records through the Restforce::DB system. It
    # allows for more intelligent decision-making regarding what constitutes
    # "stale" data during a synchronization.
    #
    # While we can tell which user _triggered_ the most recent changes to a
    # record in Salesforce, we can't tell if any modifications to that record
    # were a result of a background Apex trigger or workflow (which apply any
    # changes as if they were the user whose actions initiated the callback).
    #
    # In order to distinguish between updates made _by_ the worker and updates
    # made _in response to_ changes by the worker, we have to check the
    # record's update timestamp against the timestamp of the last known update
    # made by the system. This class serves as a mechanism to track the values
    # for this comparison.
    class TimestampCache

      # Public: Initialize a new Restforce::DB::TimestampCache.
      def initialize
        reset
      end

      # Public: Add a known update timestamp to the cache for the passed object.
      #
      # instance - A Restforce::DB::Instances::Base.
      #
      # Returns an Array of Restforce::DB::Instances::Base.
      def cache_timestamp(instance)
        @cache[key_for(instance)] = instance.last_update
      end

      # Public: Get the most recently-stored timestamp for the passed object.
      # Falls back to the retired timestamps to ensure that this run is aware of
      # the modifications made during the previous run.
      #
      # instance - A Restforce::DB::Instances::Base.
      #
      # Returns a Time or nil.
      def timestamp(instance)
        key = key_for(instance)
        @cache.fetch(key) { @retired_cache[key] }
      end

      # Public: Has the passed instance been modified since the last known
      # system-triggered update? This accounts for changes possibly introduced
      # by callbacks and triggers.
      #
      # instance - A Restforce::DB::Instances::Base.
      #
      # Returns a Boolean.
      def changed?(instance)
        return true unless instance.updated_internally?

        last_update = timestamp(instance)
        return true unless last_update

        instance.last_update > last_update
      end

      # Public: Reset the cache. Expires the previously-cached timestamps, and
      # retires the currently-cached timestamps to ensure that they are only
      # factored into the current synchronization run.
      #
      # Returns nothing.
      def reset
        @retired_cache = @cache || {}
        @cache = {}
      end

      private

      # Internal: Get a unique cache key for the passed instance.
      #
      # instance - A Restforce::DB::Instances::Base.
      #
      # Returns an Object.
      def key_for(instance)
        [instance.class, instance.id]
      end

    end

  end

end
