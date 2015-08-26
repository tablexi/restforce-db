module Restforce

  module DB

    # Restforce::DB::Tracker encapsulates a minimal API to track and configure
    # synchronization runtimes. It allows Restforce::DB to persist a "last
    # successful sync" timestamp.
    class Tracker

      attr_reader :last_run

      # Public: Initialize a Restforce::DB::Tracker. Sets a last_run timestamp
      # on Restforce::DB if the supplied tracking file already contains a stamp.
      #
      # file_path - The Path to the tracking file.
      def initialize(file_path)
        @file_path = file_path

        timestamp = File.open(@file_path, "a+") { |file| file.read }
        return if timestamp.empty?

        @last_run = Time.parse(timestamp)
        Restforce::DB.last_run = @last_run
      end

      # Public: Persist the passed time in the tracker file.
      #
      # time - A Time object.
      #
      # Returns nothing.
      def track(time)
        @last_run = time
        File.open(@file_path, "w") { |file| file.write(time.utc.iso8601) }
      end

    end

  end

end
