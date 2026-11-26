# frozen_string_literal: true

require_relative "request_context"

module OtelLogging
  # Rack middleware. Records the id of the request for the log entries of the
  # request. Put the middleware after ActionDispatch::RequestId.
  class RequestContextMiddleware
    def initialize(app)
      @app = app
    end

    def call(env)
      RequestContext.request_id = env["action_dispatch.request_id"]
      @app.call(env)
    end
  end
end
