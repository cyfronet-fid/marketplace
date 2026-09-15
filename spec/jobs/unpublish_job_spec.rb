# frozen_string_literal: true

require "rails_helper"

RSpec.describe UnpublishJob, :backend do
  let(:provider) { build_stubbed(:provider) }

  before do
    allow(Provider::Unpublish).to receive(:call)
    described_class.perform_now(provider)
  end

  it "runs the Unpublish operation of the object's class" do
    expect(Provider::Unpublish).to have_received(:call).with(provider)
  end
end
