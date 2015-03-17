module Restforce

  module DB

    module Models

      class Salesforce < Base

        def find(id)
          Instances::Salesforce.new(
            client.query("select #{lookups} from #{@model} where Id = '#{id}'").first,
            @mappings,
          )
        end

        private

        def lookups
          (Instances::Salesforce::INTERNAL_ATTRIBUTES + @mappings.keys).join(", ")
        end

        def client
          Restforce.new(
            username:       Restforce::DB.configuration.username,
            password:       Restforce::DB.configuration.password,
            security_token: Restforce::DB.configuration.security_token,
            client_id:      Restforce::DB.configuration.client_id,
            client_secret:  Restforce::DB.configuration.client_secret,
            host:           Restforce::DB.configuration.host,
          )
        end

      end

    end

  end

end
