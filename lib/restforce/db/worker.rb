require "file_daemon"

module Restforce

  module DB

    # Restforce::DB::Worker represents the primary polling loop through which
    # all record synchronization occurs.
    class Worker

      include FileDaemon

      DEFAULT_INTERVAL = 5
      DEFAULT_DELAY = 1

      attr_accessor :logger, :tracker

      # Public: Initialize a new Restforce::DB::Worker.
      #
      # options - A Hash of options to configure the worker's run. Currently
      #           supported options are:
      #           interval - The maximum polling loop rest time.
      #           delay    - The amount of time by which to offset queries.
      #           config   - The path to a client configuration file.
      #           verbose  - Display command line output? Defaults to false.
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

        %w(TERM INT).each { |signal| trap(signal) { stop } }

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

      # Internal: Perform the synchronization loop, recording the time that the
      # run is performed so that future runs can pick up where the last run
      # left off.
      #
      # Returns nothing.
      def perform
        track do
          reset!

          Restforce::DB::Registry.each do |mapping|
            task("CLEANING RECORDS", mapping) { clean mapping }
            task("PROPAGATING RECORDS", mapping) { propagate mapping }
            task("COLLECTING CHANGES", mapping) { collect mapping }
            task("UPDATING ASSOCIATIONS", mapping) { associate mapping }
          end

          # NOTE: We can only perform the synchronization after all record
          # changes have been aggregated, so this second loop is necessary.
          Restforce::DB::Registry.each do |mapping|
            task("APPLYING CHANGES", mapping) { synchronize mapping }
          end
        end
      end

      # Internal: Reset the internal state of the Worker in preparation for
      # a new synchronization loop.
      #
      # Returns nothing.
      def reset!
        runner.tick!
        @changes = Hash.new { |h, k| h[k] = Accumulator.new }
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

      # Internal: Get a Runner object which can be passed to the various
      # workflow objects to scope their record lookups.
      #
      # Returns a Restforce::DB::Runner.
      def runner
        @runner ||= Runner.new(@options.fetch(:delay) { DEFAULT_DELAY })
      end

      # Internal: Propagate unsynchronized records between the two systems for
      # the passed mapping.
      #
      # mapping - A Restforce::DB::Mapping.
      #
      # Returns nothing.
      def propagate(mapping)
        Initializer.new(mapping, runner).run
      end

      # Internal: Remove synchronized records from the database when the
      # Salesforce record no longer meets the mapping's conditions.
      #
      # mapping - A Restforce::DB::Mapping.
      #
      # Returns nothing.
      def clean(mapping)
        Cleaner.new(mapping, runner).run
      end

      # Internal: Collect a list of changes from recently-updated records for
      # the passed mapping.
      #
      # mapping - A Restforce::DB::Mapping.
      #
      # Returns nothing.
      def collect(mapping)
        Collector.new(mapping, runner).run(@changes)
      end

      # Internal: Update the associated records and Salesforce lookups for
      # records belonging to the passed mapping.
      #
      # mapping - A Restforce::DB::Mapping.
      #
      # Returns nothing.
      def associate(mapping)
        Associator.new(mapping, runner).run
      end

      # Internal: Apply the aggregated changes to the objects in both systems,
      # according to the defined mappings.
      #
      # mapping - A Restforce::DB::Mapping.
      #
      # Returns nothing.
      def synchronize(mapping)
        Synchronizer.new(mapping).run(@changes)
      end

      # Internal: Log a description and response time for a specific named task.
      #
      # name    - A String task name.
      # mapping - A Restforce::DB::Mapping.
      #
      # Returns a Boolean.
      def task(name, mapping)
        log "  #{name} between #{mapping.database_model.name} and #{mapping.salesforce_model}"
        runtime = Benchmark.realtime { yield }
        log format("  COMPLETE after %.4f", runtime)

        true
      rescue => e
        error(e)

        false
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
        puts text if @options[:verbose]

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
        logger.error(exception)
      end

    end

  end

end
