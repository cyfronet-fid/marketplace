# frozen_string_literal: true

require "rails_helper"
require_relative "../../../lib/otel_logging/request_context_middleware"

RSpec.describe OtelLogging::RequestContextMiddleware do
  subject(:response) { described_class.new(app).call(env) }

  # The application gives the fields that a log entry gets during the request.
  let(:app) { ->(_env) { [200, {}, [OtelLogging::RequestContext.to_h]] } }

  after { OtelLogging::RequestContext.reset }

  context "with the request id of ActionDispatch::RequestId" do
    let(:env) { { "action_dispatch.request_id" => "0b1f6c2e-7a55-4d0c-9a39-1c1f0e5d2b11" } }

    it "gives the request id to the log entries of the request" do
      expect(response.last).to eq(["request_id" => "0b1f6c2e-7a55-4d0c-9a39-1c1f0e5d2b11"])
    end

    it "gives the status of the application" do
      expect(response.first).to eq(200)
    end
  end

  context "without a request id" do
    let(:env) { {} }

    it "gives no request id to the log entries" do
      expect(response.last).to eq([{}])
    end
  end
end
