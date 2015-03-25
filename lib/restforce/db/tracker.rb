module Restforce

  module DB

    # Restforce::DB::Tracker encapsulates a minimal API to track and configure
    # synchronization runtimes. It allows Restforce::DB to persist a "last
    # successful sync" timestamp.
    class Tracker

      # Public: Initialize a Restforce::DB::Tracker. Sets a last_run timestamp
      # on Restforce::DB if the supplied tracking file already contains a stamp.
      #
      # file_path - The Path to the tracking file.
      def initialize(file_path)
        @file = File.open(file_path, "a+")

        timestamp = @file.read
        Restforce::DB.last_run = Time.parse(timestamp) unless timestamp.empty?
      end

      # Public: Persist the passed time in the tracker file.
      #
      # time - A Time object.
      #
      # Returns nothing.
      def track(time)
        @file.truncate(0)
        @file.print(time.utc.iso8601)
        @file.flush
        @file.rewind
      end

    end

  end

end
