# frozen_string_literal: true

require "rails_helper"
require_relative "../../../lib/otel_logging/request_context"

RSpec.describe OtelLogging::RequestContext do
  subject(:fields) { described_class.to_h }

  after { described_class.reset }

  context "without a request" do
    it { is_expected.to eq({}) }
  end

  context "with the id of a request" do
    before { described_class.request_id = "0b1f6c2e-7a55-4d0c-9a39-1c1f0e5d2b11" }

    it { is_expected.to eq("request_id" => "0b1f6c2e-7a55-4d0c-9a39-1c1f0e5d2b11") }
  end

  context "when the attributes are reset after a request" do
    before do
      described_class.request_id = "0b1f6c2e-7a55-4d0c-9a39-1c1f0e5d2b11"
      ActiveSupport::CurrentAttributes.reset_all
    end

    it { is_expected.to eq({}) }
  end
end
