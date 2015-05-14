module Restforce

  module DB

    # Restforce::DB::Adapter defines the default data conversions between
    # database and Salesforce formats. It translates Dates and Times to ISO-8601
    # format for storage in Salesforce.
    class Adapter

      # Public: Convert the passed attribute hash to a format consumable by
      # the ActiveRecord model. By default, performs no conversions.
      #
      # attributes - A Hash of attributes, with keys corresponding to a Mapping.
      #
      # Returns a Hash.
      def to_database(attributes)
        attributes.dup
      end

      # Public: Convert the passed attribute hash to a format consumable by
      # Salesforce.
      #
      # attributes - A Hash of attributes, with keys corresponding to a Mapping.
      #
      # Returns a Hash.
      def from_database(attributes)
        attributes.each_with_object({}) do |(key, value), final|
          value = value.utc if value.respond_to?(:utc)
          value = value.iso8601 if value.respond_to?(:iso8601)

          final[key] = value
        end
      end

    end

  end

end
