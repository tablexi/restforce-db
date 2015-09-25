require "file_daemon"
require "forked_process"
require "restforce/db/task_manager"
require "restforce/db/loggable"

module Restforce

  module DB

    # Restforce::DB::Worker represents the primary polling loop through which
    # all record synchronization occurs.
    class Worker

      include FileDaemon
      include Loggable

      DEFAULT_INTERVAL = 5
      DEFAULT_DELAY = 1

      # TERM and INT signals should trigger a graceful shutdown.
      GRACEFUL_SHUTDOWN_SIGNALS = %w(TERM INT).freeze

      # HUP and USR1 will reopen all files at their original paths, to
      # accommodate log rotation.
      ROTATION_SIGNALS = %w(HUP USR1).freeze

      attr_accessor :logger, :tracker

      # Public: Initialize a new Restforce::DB::Worker.
      #
      # options - A Hash of options to configure the worker's run. Currently
      #           supported options are:
      #           interval - The maximum polling loop rest time.
      #           delay    - The amount of time by which to offset queries.
      #           config   - The path to a client configuration file.
      def initialize(options = {})
        @options = options
        @interval = @options.fetch(:interval) { DEFAULT_INTERVAL }
      end

      # Public: Start the polling loop for this Worker. Synchronizes all
      # registered record types between the database and Salesforce, looping
      # indefinitely until processing is interrupted by a signal.
      #
      # Returns nothing.
      def start
        DB.reset
        DB.configure do |config|
          config.parse(@options[:config])
          config.logger = logger
        end

        GRACEFUL_SHUTDOWN_SIGNALS.each { |signal| trap(signal) { stop } }
        ROTATION_SIGNALS.each { |signal| trap(signal) { Worker.reopen_files } }

        preload

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
        Thread.new { log "Exiting..." }
        @exit = true
      end

      private

      # Internal: Populate the field cache for each Salesforce object in the
      # defined mappings.
      #
      # NOTE: To work around thread-safety issues with Typheous (and possibly
      # some other HTTP adapters, we need to fork our preloading to prevent
      # intialization of our Client object in the context of the master Worker
      # process.
      #
      # Returns a Hash.
      def preload
        forked = ForkedProcess.new

        forked.write do |writer|
          log "INITIALIZING..."
          FieldProcessor.preload
          YAML.dump(FieldProcessor.field_cache, writer)
        end

        forked.read do |reader|
          FieldProcessor.field_cache.merge!(YAML.load(reader.read))
        end

        forked.run
      end

      # Internal: Perform the synchronization loop, recording the time that the
      # run is performed so that future runs can pick up where the last run
      # left off.
      #
      # NOTE: In order to keep our long-term memory usage in check, we fork a
      # task manager to process the tasks for each synchronization loop. Once
      # the subprocess dies, its memory can be reclaimed by the OS.
      #
      # Returns nothing.
      def perform
        reset!

        track do
          forked = ForkedProcess.new

          forked.write do |writer|
            Worker.after_fork
            task_manager.perform

            runner.dump_timestamps(writer)
          end

          forked.read do |reader|
            runner.load_timestamps(reader)
          end

          begin
            forked.run
          rescue ForkedProcess::UnsuccessfulExit => e
            # NOTE: Due to thread-safety issues in any of a number of libraries
            # included in the host application (even in ActiveSupport itself),
            # our forked processes may occasionally encounter various annoying
            # and intermittent errors.
            #
            # Retrying here is our way of handling that. It's not great, but
            # it's the best we can do for now without sacrificing the benefits
            # of forking our task manager runs.
            #
            # In the event that the master process has received a kill signal,
            # we can safely crash instead of attempting a retry -- we don't want
            # to fight with intentional user actions.
            stop? ? raise(e) : retry
          end
        end
      end

      # Internal: Reset the internal state of the Worker in preparation for
      # a new synchronization loop.
      #
      # Returns nothing.
      def reset!
        runner.tick!
        Worker.before_fork
      end

      # Internal: Get a new TaskManager instance, which reflects the current
      # runner state.
      #
      # Returns a Restforce::DB::TaskManager.
      def task_manager
        TaskManager.new(runner, logger: logger)
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

          duration = Benchmark.realtime { yield }
          log format("DONE after %.4f", duration)

          tracker.track(runtime)
        else
          yield
        end
      end

      # Internal: Get a Runner object which can be passed to the various
      # workflow objects to scope their record lookups.
      #
      # Returns a Restforce::DB::Runner.
      def runner
        @runner ||= Runner.new(@options.fetch(:delay) { DEFAULT_DELAY })
      end

      # Internal: Has this worker been instructed to stop?
      #
      # Returns a boolean.
      def stop?
        @exit == true
      end

    end

  end

end
