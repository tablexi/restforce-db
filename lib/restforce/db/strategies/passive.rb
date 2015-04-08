module Restforce

  module DB

    module Strategies

      # Restforce::DB::Strategies::Passive defines an initialization strategy
      # for a mapping in which newly-discovered records should never be
      # synchronized into the other system. This strategy may be used to prevent
      # multiple insertion points from existing for a single database record.
      class Passive

        # Public: Initialize a Restforce::DB::Strategies::Passive.
        def initialize(**_)
        end

        # Public: Should the passed record be constructed in the other system?
        #
        # Returns false.
        def build?(_)
          false
        end

        # Public: Is this a passive sync strategy?
        #
        # Returns true.
        def passive?
          true
        end

      end

    end

  end

end
