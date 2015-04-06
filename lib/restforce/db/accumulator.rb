module Restforce

  module DB

    # Restforce::DB::Accumulator is responsible for the accumulation of changes
    # over the course of a single synchronization run. As we iterate over the
    # various mappings, we build a set of changes for each Salesforce ID, which
    # is then applied to all objects synchronized with that Salesforce object.
    class Accumulator

      attr_reader :changes

      # Public: Initialize a Restforce::DB::Accumulator.
      def initialize
        @changes = {}
      end

      # Public: Add a changeset to the accumulator.
      #
      # timestamp - The reported Time of the changeset.
      # changeset - A Hash of attributes.
      #
      # Returns nothing.
      def store(timestamp, changeset)
        @changes[timestamp] = changeset
      end

      # Public: Get the accumulated list of attributes after all changes have
      # been applied.
      #
      # Returns a Hash.
      def attributes
        @changes.sort.reverse.each_with_object({}) do |(_, changeset), final|
          changeset.each { |attribute, value| final[attribute] ||= value }
        end
      end

    end

  end

end
