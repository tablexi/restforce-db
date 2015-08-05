module Restforce

  module DB

    # Restforce::DB::Accumulator is responsible for the accumulation of changes
    # over the course of a single synchronization run. As we iterate over the
    # various mappings, we build a set of changes for each Salesforce ID, which
    # is then applied to all objects synchronized with that Salesforce object.
    class Accumulator < Hash

      # Public: Store the changeset under the given timestamp. If a changeset
      # for that timestamp has already been registered, merge it with the newly
      # passed changeset.
      #
      # timestamp - A Time object.
      # changeset - A Hash mapping attribute names to values.
      #
      # Returns nothing.
      def store(timestamp, changeset)
        return super unless key?(timestamp)
        self[timestamp].merge!(changeset)
      end

      # Public: Get the accumulated list of attributes after all changes have
      # been applied.
      #
      # Returns a Hash.
      def attributes
        @attributes ||= sort.reverse.inject({}) do |final, (_, changeset)|
          changeset.merge(final)
        end
      end

      # Public: Get a Hash representing the current values for the items in the
      # passed Hash, as a subset of this Accumulator's attributes Hash.
      #
      # comparison - A Hash mapping of attributes to values.
      #
      # Returns a Hash.
      def current(comparison)
        attributes.each_with_object({}) do |(attribute, value), final|
          next unless comparison.key?(attribute)
          final[attribute] = value
        end
      end

      # Public: Do the canonical attributes stored in this Accumulator differ
      # from those in the passed comparison Hash?
      #
      # comparison - A Hash mapping of attributes to values.
      #
      # Returns a Boolean.
      def changed?(comparison)
        attributes.any? do |attribute, value|
          next unless comparison.key?(attribute)
          comparison[attribute] != value
        end
      end

      # Public: Does the timestamp of the most recent change meet or exceed the
      # specified timestamp?
      #
      # timestamp - A Time object.
      #
      # Returns a Boolean.
      def up_to_date_for?(timestamp)
        keys.sort.last >= timestamp
      end

    end

  end

end
