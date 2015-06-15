require "time"
require "restforce"

require "restforce/extensions"

require "restforce/db/version"
require "restforce/db/client"
require "restforce/db/configuration"
require "restforce/db/registry"
require "restforce/db/strategy"
require "restforce/db/dsl"
require "restforce/db/synchronization_error"

require "restforce/db/association_cache"
require "restforce/db/associations/base"
require "restforce/db/associations/belongs_to"
require "restforce/db/associations/foreign_key"
require "restforce/db/associations/has_many"
require "restforce/db/associations/has_one"

require "restforce/db/field_processor"
require "restforce/db/instances/base"
require "restforce/db/instances/active_record"
require "restforce/db/instances/salesforce"

require "restforce/db/record_types/base"
require "restforce/db/record_types/active_record"
require "restforce/db/record_types/salesforce"

require "restforce/db/strategies/always"
require "restforce/db/strategies/associated"
require "restforce/db/strategies/passive"

require "restforce/db/record_cache"
require "restforce/db/timestamp_cache"
require "restforce/db/runner"

require "restforce/db/accumulator"
require "restforce/db/adapter"
require "restforce/db/associator"
require "restforce/db/attribute_map"
require "restforce/db/cleaner"
require "restforce/db/collector"
require "restforce/db/initializer"
require "restforce/db/mapping"
require "restforce/db/model"
require "restforce/db/synchronizer"
require "restforce/db/tracker"
require "restforce/db/worker"

require "restforce/db/railtie" if defined?(Rails)

module Restforce

  # Restforce::DB exposes basic Restforce client configuration methods for use
  # by the other classes in this library.
  module DB

    class << self

      attr_accessor :last_run
      attr_writer :configuration

      extend Forwardable
      def_delegators(
        :configuration,
        :logger,
        :logger=,
        :before,
      )

    end

    # Public: Get the current configuration for Restforce::DB.
    #
    # Returns a Restforce::DB::Configuration instance.
    def self.configuration
      @configuration ||= Configuration.new
    end

    # Public: Get a Restforce client based on the currently configured settings.
    #
    # Returns a Restforce::Data::Client instance.
    def self.client
      @client ||= DB::Client.new(
        username:       configuration.username,
        password:       configuration.password,
        security_token: configuration.security_token,
        client_id:      configuration.client_id,
        client_secret:  configuration.client_secret,
        host:           configuration.host,
        api_version:    configuration.api_version,
        timeout:        configuration.timeout,
        adapter:        configuration.adapter,
      )
    end

    # Public: Get the ID of the Salesforce user which is being used to access
    # the Salesforce API.
    #
    # Returns a String.
    def self.user_id
      @user_id ||= client.user_info.user_id
    end

    # Public: Configure Restforce::DB by assigning values to the current
    # configuration.
    #
    # Yields the current configuration.
    # Returns the current configuration.
    def self.configure
      yield(configuration)
      configuration
    end

    # Public: Eliminate all customizations to the current Restforce::DB
    # configuration and client.
    #
    # Returns nothing.
    def self.reset
      @configuration = nil
      @client = nil
      @user_id = nil
    end

  end

end
