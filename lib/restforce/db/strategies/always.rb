module Restforce

  module DB

    module Strategies

      # Restforce::DB::Strategies::Always defines an initialization strategy for
      # a mapping in which newly-discovered records should always be
      # synchronized from Salesforce into the database, and vice-versa.
      class Always

        # Public: Initialize a Restforce::DB::Strategies::Always.
        def initialize(**_)
        end

        # Public: Should the passed record be constructed in the other system?
        #
        # record - A Restforce::DB::Instances::Base.
        #
        # Returns a Boolean.
        def build?(record)
          !record.synced?
        end

        # Public: Is this a passive sync strategy?
        #
        # Returns false.
        def passive?
          false
        end

      end

    end

  end

end
