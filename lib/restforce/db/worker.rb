module Restforce

  module DB

    # Restforce::DB::Worker represents the primary polling loop through which
    # all record synchronization occurs.
    class Worker

      DEFAULT_INTERVAL = 5
      DEFAULT_DELAY = 1

      class << self

        # Public: Store the list of currently open file descriptors so that they
        # may be reopened when a new process is spawned.
        #
        # Returns nothing.
        def before_fork
          return if @files_to_reopen

          @files_to_reopen = []
          ObjectSpace.each_object(File) do |file|
            @files_to_reopen << file unless file.closed?
          end
        end

        # Public: Reopen all file descriptors that have been stored through the
        # before_fork hook.
        #
        # Returns nothing.
        def after_fork
          @files_to_reopen.each do |file|
            begin
              file.reopen file.path, "a+"
              file.sync = true
            rescue ::Exception # rubocop:disable HandleExceptions, RescueException
            end
          end
        end

      end

      attr_accessor :logger, :tracker

      # Public: Initialize a new Restforce::DB::Worker.
      #
      # options - A Hash of options to configure the worker's run. Currently
      #           supported options are:
      #           interval - The maximum polling loop rest time.
      #           config   - The path to a client configuration file.
      #           verbose  - Display command line output? Defaults to false.
      def initialize(options = {})
        @verbose = options.fetch(:verbose) { false }
        @interval = options.fetch(:interval) { DEFAULT_INTERVAL }
        @delay = options.fetch(:delay) { DEFAULT_DELAY }

        Restforce::DB.reset
        Restforce::DB.configure { |config| config.parse(options[:config]) }
      end

      # Public: Start the polling loop for this Worker. Synchronizes all
      # registered record types between the database and Salesforce, looping
      # indefinitely until processing is interrupted by a signal.
      #
      # Returns nothing.
      def start
        trap("TERM") do
          Thread.new { log "Exiting..." }
          stop
        end

        trap("INT") do
          Thread.new { log "Exiting..." }
          stop
        end

        loop do
          runtime = Benchmark.realtime { perform }
          sleep(@interval - runtime) if runtime < @interval && !stop?

          break if stop?
        end
      end

      # Public: Instruct the worker to stop running at the end of the current
      # processing loop.
      #
      # Returns nothing.
      def stop
        @exit = true
      end

      private

      # Internal: Perform the synchronization loop, recording the time that the
      # run is performed so that future runs can pick up where the last run
      # left off.
      #
      # Returns nothing.
      def perform
        track do
          Restforce::DB::Mapping.each do |mapping|
            synchronize mapping
          end
        end
      end

      # Internal: Run the passed block, updating the tracker with the time at
      # which the run was initiated.
      #
      # Yields to a passed block.
      # Returns nothing.
      def track
        if tracker
          runtime = Time.now

          if tracker.last_run
            log "SYNCHRONIZING from #{tracker.last_run.iso8601}"
          else
            log "SYNCHRONIZING"
          end

          yield

          log "DONE"
          tracker.track(runtime)
        else
          yield
        end
      end

      # Internal: Synchronize the objects in the database and Salesforce
      # corresponding to the passed record type.
      #
      # mapping - A Restforce::DB::Mapping.
      #
      # Returns a Boolean.
      def synchronize(mapping)
        log "  SYNCHRONIZE #{mapping.database_model.name} with #{mapping.salesforce_model}"
        runtime = Benchmark.realtime { mapping.synchronizer.run(delay: @delay) }
        log format("  COMPLETE after %.4f", runtime)

        return true
      rescue => e
        error(e)

        return false
      end

      # Internal: Has this worker been instructed to stop?
      #
      # Returns a boolean.
      def stop?
        @exit == true
      end

      # Internal: Log the passed text at the specified level.
      #
      # text  - The piece of text which should be logged for this worker.
      # level - The level at which the text should be logged. Defaults to :info.
      #
      # Returns nothing.
      def log(text, level = :info)
        puts text if @verbose

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
        log "#{exception.message}\n#{exception.backtrace.join("\n")}", :error
      end

    end

  end

end
