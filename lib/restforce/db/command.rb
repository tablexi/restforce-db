require "daemons"
require "optparse"

module Restforce

  module DB

    # Restforce::DB::Command represents the command line interface for our
    # daemonized processing loop. It captures a set of options from the command
    # line to configure the running worker thread for synchronizing data.
    class Command

      # Public: Initialize a new Restforce::DB::Command.
      #
      # args - A set of command line arguments to pass to the OptionParser.
      def initialize(args)
        @options = {
          verbose: false,
          pid_dir: Rails.root.join("tmp", "pids"),
          config:  Rails.root.join("config", "restforce-db.yml"),
          tracker: Rails.root.join("config", ".restforce"),
          logfile: Rails.root.join("log", "restforce-db.log"),
        }

        @args = parser.parse!(args)
      end

      # Public: Initialize the daemonized processing loop for Restforce::DB.
      #
      # Returns nothing.
      def daemonize
        dir = @options[:pid_dir]
        Dir.mkdir(dir) unless File.exist?(dir)

        daemon_args = {
          dir: @options[:pid_dir],
          dir_mode: :normal,
          monitor: @monitor,
          ARGV: @args,
        }

        Restforce::DB::Worker.before_fork
        Daemons.run_proc("restforce-db", daemon_args) do |*_args|
          run @options
        end
      end

      private

      # Internal: Initiate a worker thread for Restforce::DB's record
      # synchronization processing loop.
      #
      # options - A Hash of run configuration options for the worker.
      #
      # Returns nothing.
      def run(options = {})
        Dir.chdir(Rails.root)

        Restforce::DB::Worker.after_fork
        Restforce::DB::Worker.logger ||= logger
        Restforce::DB::Worker.tracker ||= tracker

        worker = Restforce::DB::Worker.new(options)
        worker.start
      rescue => e
        Restforce::DB::Worker.logger.fatal e
        STDERR.puts e.message
        exit 1
      end

      # Internal: Get an OptionParser for the Restforce::DB CLI.
      #
      # Returns an OptionParser.
      def parser # rubocop:disable MethodLength
        @parser ||= OptionParser.new do |opt|
          opt.banner = "Usage: #{File.basename($PROGRAM_NAME)} [options] start|stop|restart|run"

          opt.on("-h", "--help", "Show this message") do
            puts opt
            exit 1
          end
          opt.on("-c FILE", "--config FILE", "The location of a Restforce credentials file.") do |file|
            @options[:config] = file
          end
          opt.on("-i N", "--interval N", "Amount of time to wait between synchronizations.") do |n|
            @options[:interval] = n.to_i
          end
          opt.on("-l FILE", "--logfile FILE", "The file where logging output should be captured.") do |file|
            @options[:logfile] = file
          end
          opt.on("--pid-dir DIR", "The directory in which to store the pidfile.") do |dir|
            @options[:pid_dir] = dir
          end
          opt.on("-t FILE", "--tracker FILE", "The file where run characteristics should be logged.") do |file|
            @options[:tracker] = file
          end
          opt.on("-v", "--verbose", "Turn on noisy logging.") do
            @options[:verbose] = true
          end
        end
      end

      # Internal: Get a Logger instance to capture output from the sync worker.
      # Makes the default log formatting a bit more reader-friendly.
      #
      # Returns a Logger.
      def logger
        @logger ||= Logger.new(@options[:logfile]).tap do |logger|
          logger.formatter = proc do |severity, datetime, _progname, msg|
            "#{severity} [#{datetime.strftime('%Y-%m-%d %H:%M:%S')}] #{msg}\n"
          end
        end
      end

      # Internal: Get a Tracker instance to manage run characteristics.
      #
      # Returns a Restforce::DB::Tracker.
      def tracker
        @tracker ||= Tracker.new(@options[:tracker])
      end

    end

  end

end
