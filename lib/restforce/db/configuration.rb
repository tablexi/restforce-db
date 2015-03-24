require "yaml"

module Restforce

  module DB

    # Restforce::DB::Configuration exposes a handful of straightforward write
    # and read methods to allow users to configure Restforce::DB.
    class Configuration

      attr_accessor(*%i(
        username
        password
        security_token
        client_id
        client_secret
        host
      ))

      # Public: Parse a supplied YAML file for a set of credentials, and use
      # them to populate the attributes on this configuraton object.
      #
      # file_path - A String or Path referencing a client configuration file.
      #
      # Returns nothing.
      def parse(file_path)
        settings = YAML.load_file(file_path)
        load(settings["client"])
      end

      # Public: Populate this configuration object from a Hash of credentials.
      #
      # configurations - A Hash of credentials, with keys matching the names
      #                  of the attributes for this class.
      #
      # Returns nothing.
      def load(configurations)
        self.username       = configurations["username"]
        self.password       = configurations["password"]
        self.security_token = configurations["security_token"]
        self.client_id      = configurations["client_id"]
        self.client_secret  = configurations["client_secret"]
        self.host           = configurations["host"]
      end

    end

  end

end
