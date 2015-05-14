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
        sort.reverse.inject({}) do |final, (_, changeset)|
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
        attributes.each_with_object({}) do |(attribute, value), diff|
          next unless comparison.key?(attribute)
          diff[attribute] = value
        end
      end

      # Public: Get a Hash representing the changes that would need to be
      # applied to make a passed Hash a subset of this Accumulator's derived
      # attributes Hash.
      #
      # comparison - A Hash mapping of attributes to values.
      #
      # Returns a Hash.
      def diff(comparison)
        attributes.each_with_object({}) do |(attribute, value), diff|
          next unless comparison.key?(attribute)
          next if comparison[attribute] == value

          diff[attribute] = value
        end
      end

    end

  end

end
