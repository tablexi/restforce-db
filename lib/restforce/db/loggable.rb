module Restforce

  module DB

    # Restforce::DB::Loggable defines shared behaviors for objects which
    # need access to generic logging functionality.
    module Loggable

      # Public: Add a `logger` attribute to the object including this module.
      #
      # base - The object which is including the `Loggable` module.
      def self.included(base)
        base.send :attr_accessor, :logger
      end

      private

      # Internal: Log the passed text at the specified level.
      #
      # text  - The piece of text which should be logged for this worker.
      # level - The level at which the text should be logged. Defaults to :info.
      #
      # Returns nothing.
      def log(text, level = :info)
        return unless logger
        logger.send(level, text)
      end

      # Internal: Log an error for the worker, outputting the entire error
      # stacktrace and applying the appropriate log level.
      #
      # exception - An Exception object.
      #
      # Returns nothing.
      def error(exception)
        log exception, :error
      end

    end

  end

end
