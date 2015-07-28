module Restforce

  module DB

    # Restforce::DB::AttributeMap encapsulates the logic for converting between
    # various representations of attribute hashes.
    #
    # For the purposes of our mappings, a "normalized" attribute Hash maps the
    # Salesforce field names to Salesforce-compatible values. Value conversion
    # into and out of the database occurs through a lightweight Adapter object.
    class AttributeMap

      # Public: Initialize a Restforce::DB::AttributeMap.
      #
      # database_model   - A Class compatible with ActiveRecord::Base.
      # salesforce_model - A String name of an object type in Salesforce.
      # fields           - A Hash of mappings between database columns and
      #                    fields in Salesforce.
      # adapter          - An adapter object which should be used to convert
      #                    between data formats.
      def initialize(database_model, salesforce_model, fields = {}, adapter = Adapter.new)
        @field_maps = {
          database_model   => AttributeMaps::Database.new(fields, adapter),
          salesforce_model => AttributeMaps::Salesforce.new(fields),
        }
      end

      # Public: Build a normalized Hash of attributes from the appropriate set
      # of mappings. The keys of the resulting mapping Hash will correspond to
      # the Salesforce field names.
      #
      # from_format - A String or Class reflecting the record type from which
      #               the attribute Hash is being compiled.
      # record      - The underlying record for which attributes should be
      #               collected.
      #
      # Returns a Hash.
      def attributes(from_format, record)
        @field_maps[from_format].attributes(record)
      end

      # Public: Convert a Hash of normalized attributes to a format compatible
      # with a specific platform.
      #
      # to_format  - A String or Class reflecting the record type for which the
      #              attribute Hash is being compiled.
      # attributes - A Hash of attributes, with keys corresponding to the
      #              normalized attribute names.
      #
      # Examples
      #
      #   mapping = AttributeMap.new(
      #     MyClass,
      #     "Object__c",
      #     some_key: "SomeField__c",
      #   )
      #
      #   mapping.convert(MyClass, "Some_Field__c" => "some value")
      #   # => { some_key: "some value" }
      #
      #   mapping.convert("Object__c", "Some_Field__c" => "some other value")
      #   # => { "Some_Field__c" => "some other value" }
      #
      # Returns a Hash.
      def convert(to_format, attributes)
        @field_maps[to_format].convert(attributes)
      end

    end

  end

end
