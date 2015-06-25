module Restforce

  module DB

    # Restforce::DB::Task is a lightweight interface for task classes which
    # expose pieces of functionality to a master worker process. Each task
    # should accept a mapping and a runner, and expose a #run method to interact
    # with the runner's data in some way.
    class Task

      # Public: Initialize a Restforce::DB::Task.
      #
      # mapping - A Restforce::DB::Mapping.
      # runner  - A Restforce::DB::Runner.
      def initialize(mapping, runner = Runner.new)
        @mapping = mapping
        @runner = runner
      end

      # Public: Run this task. Must be overridden by subclasses.
      #
      # Raises NotImplementedError.
      # Returns nothing.
      def run(*_)
        raise NotImplementedError
      end

    end

  end

end
