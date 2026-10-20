# frozen_string_literal: true

module BosRetryable
  extend ActiveSupport::Concern

  included do
    queue_as :orders

    retry_on Faraday::TimeoutError, Faraday::ConnectionFailed, wait: ->(executions) { 3**executions }, attempts: 5
  end
end
