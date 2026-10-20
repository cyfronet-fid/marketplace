# frozen_string_literal: true

require "rails_helper"

RSpec.describe Infrastructure::Destroy, type: :service do
  subject(:destroy) { described_class.call(infrastructure, client: ApplicationDeploymentManager::Client.new(access_token: "t")) }

  let(:deployment_url) { "https://adm.test.example.com/adim/deployment/dep-1" }
  let(:infrastructure) do
    create(:infrastructure, :running, deployment_id: "dep-1", project_item: create(:project_item, status_type: :ready))
  end

  context "when ADM accepts the deletion" do
    before do
      stub_request(:delete, deployment_url).to_return(
        status: 202,
        body: { message: "Deleting" }.to_json,
        headers: {
          "Content-Type" => "application/json"
        }
      )
      destroy
    end

    it "marks the infrastructure destroyed" do
      expect(infrastructure.reload.state).to eq("destroyed")
    end

    it "closes the project item" do
      expect(infrastructure.project_item.reload).to have_attributes(
        status_type: "closed",
        status: "Infrastructure has been destroyed"
      )
    end
  end

  context "when ADM no longer knows the deployment" do
    before do
      stub_request(:delete, deployment_url).to_return(status: 404)
      destroy
    end

    it "marks the infrastructure destroyed" do
      expect(infrastructure.reload.state).to eq("destroyed")
    end
  end

  context "when ADM fails to delete the deployment" do
    before do
      stub_request(:delete, deployment_url).to_return(
        status: 503,
        body: { description: "Try again later" }.to_json,
        headers: {
          "Content-Type" => "application/json"
        }
      )
      destroy
    end

    it "marks the infrastructure failed" do
      expect(infrastructure.reload).to have_attributes(state: "failed", last_error: /\ADestroy failed: .*Try again/)
    end

    it "rejects the project item" do
      expect(infrastructure.project_item.reload).to have_attributes(
        status_type: "rejected",
        status: /\AFailed to destroy infrastructure: .*Try again later/
      )
    end
  end
end
