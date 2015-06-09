module Restforce

  module DB

    # Restforce::DB::SynchronizationError is a thin wrapper for any sort of
    # exception that might crop up during our record synchronization. It exposes
    # the Salesforce ID (or database identifier, for unsynced records) of the
    # record which triggered the exception.
    class SynchronizationError < RuntimeError

      attr_reader :base_exception

      extend Forwardable
      def_delegators(
        :base_exception,
        :class,
        :backtrace,
      )

      # Public: Initialize a new SynchronizationError.
      #
      # base_exception - An exception which should be logged.
      # instance       - A Restforce::DB::Instances::Base representing a record.
      def initialize(base_exception, instance)
        @base_exception = base_exception
        @instance = instance
      end

      # Public: Get the message for this exception. Prepends the Salesforce ID.
      #
      # Returns a String.
      def message
        debug_info = [
          @instance.mapping.database_model,
          @instance.mapping.salesforce_model,
          @instance.id,
        ]

        "[#{debug_info.join('|')}] #{base_exception.message}"
      end

    end

  end

end
