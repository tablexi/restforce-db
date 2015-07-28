module Restforce

  module DB

    module AttributeMaps

      # Restforce::DB::AttributeMaps::Database encapsulates the logic for
      # compiling and parsing normalized attribute hashes from/for ActiveRecord
      # objects.
      class Database

        # Public: Initialize a Restforce::DB::AttributeMaps::Database.
        #
        # fields  - A Hash of mappings between database columns and fields in
        #           Salesforce.
        # adapter - An adapter object which should be used to convert between
        #           data formats.
        def initialize(fields, adapter = Adapter.new)
          @fields = fields
          @adapter = adapter
        end

        # Public: Build a normalized Hash of attributes from the appropriate set
        # of mappings. The keys of the resulting mapping Hash will correspond to
        # the Salesforce field names.
        #
        # record - The underlying ActiveRecord object for which attributes
        #          should be collected.
        #
        # Returns a Hash.
        def attributes(record)
          attributes = @fields.keys.each_with_object({}) do |attribute, values|
            values[attribute] = record.send(attribute)
          end
          attributes = @adapter.from_database(attributes)

          @fields.each_with_object({}) do |(attribute, mapping), final|
            final[mapping] = attributes[attribute]
          end
        end

        # Public: Convert a Hash of normalized attributes to a format suitable
        # for consumption by an ActiveRecord object.
        #
        # attributes - A Hash of attributes, with keys corresponding to the
        #              normalized Salesforce attribute names.
        #
        # Examples
        #
        #   attribute_map = AttributeMaps::Database.new(
        #     some_key: "SomeField__c",
        #   )
        #
        #   attribute_map.convert(MyClass, "Some_Field__c" => "some value")
        #   # => { some_key: "some value" }
        #
        # Returns a Hash.
        def convert(attributes)
          attributes = @fields.each_with_object({}) do |(attribute, mapping), converted|
            next unless attributes.key?(mapping)
            converted[attribute] = attributes[mapping]
          end

          @adapter.to_database(attributes)
        end

      end

    end

  end

end
