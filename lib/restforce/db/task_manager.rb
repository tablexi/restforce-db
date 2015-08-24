require "restforce/db/loggable"
require "restforce/db/task"
require "restforce/db/accumulator"
require "restforce/db/attacher"
require "restforce/db/associator"
require "restforce/db/cleaner"
require "restforce/db/collector"
require "restforce/db/initializer"
require "restforce/db/synchronizer"

module Restforce

  # :nodoc:
  module DB

    # TaskMapping is a small data structure used to pass top-level task
    # information through to a SynchronizationError when necessary.
    TaskMapping = Struct.new(:id, :mapping)

    # Restforce::DB::TaskManager defines the run sequence and invocation of each
    # of the Restforce::DB::Task subclasses during a single processing loop for
    # the top-level Worker object.
    class TaskManager

      include Loggable

      # Public: Initialize a new Restforce::DB::TaskManager for a given runner
      # state.
      #
      # runner - A Restforce::DB::Runner for a specific period of time.
      # logger - A Logger object (optional).
      def initialize(runner, logger: nil)
        @runner = runner
        @logger = logger
        @changes = Hash.new { |h, k| h[k] = Accumulator.new }
      end

      # Public: Run each of the sync tasks in a defined order for the supplied
      # runner's current state.
      #
      # Returns nothing.
      def perform
        Registry.each do |mapping|
          run("CLEANING RECORDS", Cleaner, mapping)
          run("ATTACHING RECORDS", Attacher, mapping)
          run("PROPAGATING RECORDS", Initializer, mapping)
          run("COLLECTING CHANGES", Collector, mapping)
        end

        # NOTE: We can only perform the synchronization after all record changes
        # have been aggregated, so this second loop is necessary.
        Registry.each do |mapping|
          run("UPDATING ASSOCIATIONS", Associator, mapping)
          run("APPLYING CHANGES", Synchronizer, mapping)
        end
      end

      private

      # Internal: Log a description and response time for a specific named task.
      #
      # name       - A String task name.
      # task_class - A Restforce::DB::Task subclass.
      # mapping    - A Restforce::DB::Mapping.
      #
      # Returns a Boolean.
      def run(name, task_class, mapping)
        log "  #{name} between #{mapping.database_model.name} and #{mapping.salesforce_model}"
        runtime = Benchmark.realtime { task task_class, mapping }
        log format("  FINISHED #{name} after %.4f", runtime)

        true
      rescue => e
        error(e)

        false
      end

      # Internal: Run the passed mapping through the supplied Task class.
      #
      # task_class - A Restforce::DB::Task subclass.
      # mapping    - A Restforce::DB::Mapping.
      #
      # Returns nothing.
      def task(task_class, mapping)
        task_class.new(mapping, @runner).run(@changes)
      rescue Faraday::Error::ClientError => e
        task_mapping = TaskMapping.new(task_class, mapping)
        error SynchronizationError.new(e, task_mapping)
      end

    end

  end

end
