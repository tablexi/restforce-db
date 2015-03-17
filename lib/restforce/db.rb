require "restforce"
require "restforce/extensions"

require "restforce/db/version"
require "restforce/db/configuration"

require "restforce/db/instances/base"
require "restforce/db/instances/active_record"
require "restforce/db/instances/salesforce"

require "restforce/db/models/base"
require "restforce/db/models/active_record"
require "restforce/db/models/salesforce"

require "restforce/db/model"

module Restforce

  module DB

    class << self
      attr_writer :configuration
    end

    def self.configuration
      @configuration ||= Configuration.new
    end

    def self.client
      @client ||= Restforce.new(
        username:       configuration.username,
        password:       configuration.password,
        security_token: configuration.security_token,
        client_id:      configuration.client_id,
        client_secret:  configuration.client_secret,
        host:           configuration.host,
      )
    end

    def self.configure
      yield(configuration)
    end

    def self.reset
      @configuration = nil
      @client = nil
    end

  end

end
