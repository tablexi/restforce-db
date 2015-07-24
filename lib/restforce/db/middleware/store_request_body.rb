module Restforce

  module DB

    module Middleware

      # Public: A Faraday middleware to store the request body in the environment.
      #
      # This works around an issue with Faraday where the request body is squashed by
      # the response body, once a request has been made.
      #
      # See also:
      # - https://github.com/lostisland/faraday/issues/163
      # - https://github.com/lostisland/faraday/issues/297
      class StoreRequestBody < Faraday::Middleware

        # Public: Executes this middleware.
        #
        # request_env - The request's Env from Faraday.
        def call(request_env)
          request_env[:request_body] = request_env[:body]
          @app.call(request_env)
        end

      end

    end

  end

end
