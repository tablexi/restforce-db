require "restforce"

require "restforce/db/version"
require "restforce/db/configuration"

module Restforce

  module DB

    class << self
      attr_writer :configuration
    end

    def self.configuration
      @configuration ||= Configuration.new
    end

    def self.reset
      @configuration = Configuration.new
    end

    def self.configure
      yield(configuration)
    end

  end

end
