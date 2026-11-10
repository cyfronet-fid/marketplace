# frozen_string_literal: true

# Faraday middleware limiting the response body size while it is streamed, so an oversized response
# is rejected before it is read into memory:
#
#   Faraday.new do |f|
#     f.response :follow_redirects # before ResponseSizeLimit, so each redirect hop gets its own buffer
#     f.use HttpMiddleware::ResponseSizeLimit, max: 1.megabyte
#     f.adapter :net_http
#   end
class HttpMiddleware::ResponseSizeLimit < Faraday::Middleware
  class ResponseTooLargeError < Faraday::Error
  end

  def initialize(app, max:)
    super(app)
    @max = max
  end

  def call(env)
    body = +""
    env.request.on_data =
      proc do |chunk, received|
        raise ResponseTooLargeError, "Response is larger than #{@max} bytes" if received > @max

        body << chunk
      end

    app.call(env).on_complete { |response_env| response_env.body = body }
  end
end
