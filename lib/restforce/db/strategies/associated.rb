module Restforce

  module DB

    module Strategies

      # Restforce::DB::Strategies::Associated defines an initialization strategy
      # for a mapping in which newly-discovered records should only be
      # synchronized into the other system when a specific associated record
      # has already been synchronized.
      class Associated

        # Public: Initialize a Restforce::DB::Strategies::Associated for the
        # passed mapping.
        #
        # with - A Symbol name of the association which should be checked.
        def initialize(with:)
          @association = with.to_sym
        end

        # Public: Should the passed record be constructed in the other system?
        #
        # record - A Restforce::DB::Instances::Base.
        #
        # Returns a Boolean.
        def build?(record)
          !record.synced? && target_association(record.mapping).synced_for?(record)
        end

        # Public: Is this a passive sync strategy?
        #
        # Returns false.
        def passive?
          false
        end

        private

        # Internal: Get the target association for the desired associated record
        # lookup.
        #
        # mapping - A Restforce::DB::Mapping
        #
        # Returns a Restforce::DB::Associations::Base.
        def target_association(mapping)
          @target_association ||= mapping.associations.detect do |association|
            association.name == @association
          end
          @target_association || raise(ArgumentError, ":with must correspond to a defined association")
        end

      end

    end

  end

end
