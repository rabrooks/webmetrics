## TODO Work in progrss

# module Webmetrics
#   class Middleware

#     def initialize(app)
#       @app = app
#     end

#     def call(env)
#       webmetrics_session = Webmetrics(env)

#       status, headers, body = @app.call(env)

#       # sets a tracking cookie on the response
#       response = Rack::Response.new body, status, headers
#       webmetrics_session.set_cookie(response)

#       response.finish
#     end

#   end
# end
