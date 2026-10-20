# frozen_string_literal: true

require "rails_helper"

RSpec.describe DeployableService::DeploymentJob, type: :job do
  let(:project_item) { create(:project_item) }

  before { allow(Infrastructure::Deploy).to receive(:call) }

  it "deploys the project item through ADM" do
    described_class.perform_now(project_item)
    expect(Infrastructure::Deploy).to have_received(:call).with(project_item)
  end

  it "uses the deployments queue" do
    expect(described_class.new.queue_name).to eq("deployments")
  end
end
