# frozen_string_literal: true

require "active_support"
require "active_support/current_attributes"

module OtelLogging
  # Fields of the current HTTP request. Rails resets the attributes after each
  # request and after each job. Give the class to JsonFormatter as a context:
  # the class delegates #to_h to the current instance.
  class RequestContext < ActiveSupport::CurrentAttributes
    attribute :request_id

    def to_h
      { "request_id" => request_id }.compact
    end
  end
end
