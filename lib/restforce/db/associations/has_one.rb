module Restforce

  module DB

    module Associations

      # Restforce::DB::Associations::HasOne defines a relationship in which a
      # Salesforce ID for this Mapping's database record exists on the named
      # database association's Mapping.
      class HasOne < Base

        # :nodoc:
        def build(_database_record, _salesforce_record)
          # TODO
        end

      end

    end

  end

end
