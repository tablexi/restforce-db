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
      #           config   - The path to a client configuration file.
      #           verbose  - Display command line output? Defaults to false.
      def initialize(options = {})
        @verbose = options.fetch(:verbose) { false }
        @interval = options.fetch(:interval) { DEFAULT_INTERVAL }
        @runner = Runner.new(options.fetch(:delay) { DEFAULT_DELAY })

        DB.reset
        DB.configure { |config| config.parse(options[:config]) }
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
        @runner.tick!
        @changes = Hash.new { |h, k| h[k] = Accumulator.new }

        track do
          Restforce::DB::Mapping.each do |mapping|
            task("PROPAGATING RECORDS", mapping) { propagate mapping }
            task("COLLECTING CHANGES", mapping) { collect mapping }
          end

          # NOTE: We can only perform the synchronization after all record
          # changes have been aggregated, so this second loop is necessary.
          Restforce::DB::Mapping.each do |mapping|
            task("APPLYING CHANGES", mapping) { synchronize mapping }
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

      # Internal: Propagate unsynchronized records between the two systems for
      # the passed mapping.
      #
      # mapping - A Restforce::DB::Mapping.
      #
      # Returns nothing.
      def propagate(mapping)
        Initializer.new(mapping, @runner).run
      end

      # Internal: Collect record changes for the passd mapping/
      #
      # mapping - A Restforce::DB::Mapping.
      #
      # Returns nothing.
      def collect(mapping)
        Collector.new(mapping, @runner).run(@changes)
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

      # Internal: Time and log the output of a named task.
      #
      # name    - A String task name.
      # mapping - A Restforce::DB::Mapping.
      #
      # Returns a Boolean.
      def task(name, mapping)
        log "  #{name} between #{mapping.database_model.name} and #{mapping.salesforce_model}"
        runtime = Benchmark.realtime { yield }
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
