module Restforce

  module DB

    module AttributeMaps

      # Restforce::DB::AttributeMaps::Database encapsulates the logic for
      # compiling and parsing normalized attribute hashes from/for Salesforce
      # objects.
      class Salesforce

        # Public: Initialize a Restforce::DB::AttributeMaps::Salesforce.
        #
        # fields - A Hash of mappings between database columns and fields in
        #          Salesforce.
        def initialize(fields)
          @fields = fields
        end

        # Public: Build a normalized Hash of attributes from the appropriate set
        # of mappings. The keys of the resulting mapping Hash will correspond to
        # the Salesforce field names.
        #
        # record - The underlying Salesforce object for which attributes should
        #          be collected.
        #
        # Returns a Hash.
        def attributes(record)
          @fields.values.each_with_object({}) do |mapping, values|
            values[mapping] = mapping.split(".").inject(record) do |value, portion|
              value[portion]
            end
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
        #   attribute_map = AttributeMaps::Salesforce.new(
        #     some_key: "SomeField__c",
        #   )
        #
        #   mapping.convert("Object__c", "Some_Field__c" => "some other value")
        #   # => { "Some_Field__c" => "some other value" }
        #
        # Returns a Hash.
        def convert(attributes)
          attributes.dup
        end

      end

    end

  end

end
