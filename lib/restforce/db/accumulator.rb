module Restforce

  module DB

    # Restforce::DB::Accumulator is responsible for the accumulation of changes
    # over the course of a single synchronization run. As we iterate over the
    # various mappings, we build a set of changes for each Salesforce ID, which
    # is then applied to all objects synchronized with that Salesforce object.
    class Accumulator < Hash

      # Public: Get the accumulated list of attributes after all changes have
      # been applied.
      #
      # Returns a Hash.
      def attributes
        sort.reverse.each_with_object({}) do |(_, changeset), final|
          changeset.each { |attribute, value| final[attribute] ||= value }
        end
      end

    end

  end

end
