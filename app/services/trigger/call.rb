# frozen_string_literal: true

require "base64"

class Trigger::Call
  def initialize(trigger)
    @trigger = trigger
  end

  def call
    @trigger.authorization.is_a?(OMS::Authorization::Basic) ? handle_basic_auth(@trigger.authorization) : handle_no_auth
  end

  private

  def handle_no_auth
    Faraday.public_send(@trigger.method, @trigger.url)
  end

  def handle_basic_auth(basic_auth)
    Faraday.public_send(@trigger.method, @trigger.url, authorization: encode_header(basic_auth))
  end

  def encode_header(basic_auth)
    "Basic " + Base64.urlsafe_encode64(basic_auth.user + ":" + basic_auth.password)
  end
end
