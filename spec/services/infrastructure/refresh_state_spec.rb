# frozen_string_literal: true

require "rails_helper"

RSpec.describe Infrastructure::RefreshState, type: :service do
  subject(:refresh) { described_class.call(infrastructure, client: Adm::Client.new(access_token: "t")) }

  let(:infrastructure) do
    create(
      :infrastructure,
      :creating,
      deployment_id: "dep-1",
      last_state_check_at: 2.minutes.ago,
      output_names: %w[jupyter_url jupyter_ip],
      project_item: create(:project_item, status: "created", status_type: :created)
    )
  end
  let(:deployment) { { id: "dep-1", status: "pending", details: "", outputs: [] } }

  before do
    stub_request(:get, "https://adm.test.example.com/adim/deployment/dep-1").to_return(
      status: 200,
      body: deployment.to_json,
      headers: {
        "Content-Type" => "application/json"
      }
    )
  end

  context "when the deployment is pending" do
    it "keeps the infrastructure creating and records the state check" do
      refresh
      expect(infrastructure.reload).to have_attributes(state: "creating",
                                                       last_state_check_at: be_within(5.seconds).of(Time.current))
    end
  end

  context "when the deployment is running, still being configured" do
    let(:deployment) do
      { id: "dep-1", status: "running", outputs: [name: "jupyter_url", value: "https://hub.vm.fedcloud.eu"] }
    end

    before { refresh }

    it "keeps the infrastructure creating" do
      expect(infrastructure.reload.state).to eq("creating")
    end

    it "does not link the project item to the deployment URL yet" do
      expect(infrastructure.project_item.reload).to have_attributes(status_type: "created", deployment_link: be_blank)
    end
  end

  context "when the deployment is configured with a URL output" do
    let(:deployment) do
      { id: "dep-1", status: "configured", outputs: [name: "jupyter_url", value: "https://hub.vm.fedcloud.eu"] }
    end

    before { refresh }

    it "marks the infrastructure configured" do
      expect(infrastructure.reload.state).to eq("configured")
    end

    it "stores the outputs" do
      expect(infrastructure.reload.outputs).to eq("jupyter_url" => "https://hub.vm.fedcloud.eu")
    end

    it "marks the project item ready at the deployment URL" do
      expect(infrastructure.project_item.reload).to have_attributes(
        status_type: "ready",
        deployment_link: "https://hub.vm.fedcloud.eu"
      )
    end
  end

  %w[stopped off].each do |status|
    context "when the deployment is #{status}" do
      let(:deployment) { { id: "dep-1", status: status, outputs: [name: "jupyter_ip", value: "https://10.0.0.1"] } }

      it "marks the infrastructure running" do
        expect { refresh }.to change { infrastructure.reload.state }.from("creating").to("running")
      end
    end
  end

  context "when a DNS URL output appears after an IP address one" do
    let(:deployment) do
      {
        id: "dep-1",
        status: "configured",
        outputs: [{ name: "jupyter_url", value: "https://hub.vm.fedcloud.eu" },
                  { name: "jupyter_ip", value: "https://10.0.0.1" }]
      }
    end

    before do
      infrastructure.project_item.update!(deployment_link: "https://10.0.0.1", status_type: :ready)
      refresh
    end

    it "switches the project item to the DNS URL" do
      expect(infrastructure.project_item.reload.deployment_link).to eq("https://hub.vm.fedcloud.eu")
    end
  end

  context "when the project item already links to the deployment URL" do
    let(:deployment) do
      { id: "dep-1", status: "configured", outputs: [name: "jupyter_url", value: "https://hub.vm.fedcloud.eu"] }
    end

    before { infrastructure.project_item.update!(deployment_link: "https://hub.vm.fedcloud.eu", status: "Custom") }

    it "leaves the project item untouched" do
      expect { refresh }.not_to(change { infrastructure.project_item.reload.status })
    end
  end

  context "when the deployment is stopped without outputs" do
    let(:deployment) { { id: "dep-1", status: "stopped", outputs: [] } }

    before do
      infrastructure.update!(outputs: { "jupyter_url" => "https://hub.vm.fedcloud.eu" })
      refresh
    end

    it "keeps the stored outputs" do
      expect(infrastructure.reload.outputs).to eq("jupyter_url" => "https://hub.vm.fedcloud.eu")
    end
  end

  %w[failed unconfigured].each do |status|
    context "when the deployment is #{status}" do
      let(:deployment) { { id: "dep-1", status: status, details: "Error launching the VMs" } }

      before { refresh }

      it "marks the infrastructure failed with the ADM details" do
        expect(infrastructure.reload).to have_attributes(state: "failed", last_error: "Error launching the VMs")
      end

      it "rejects the project item" do
        expect(infrastructure.project_item.reload).to have_attributes(
          status_type: "rejected",
          status: "Deployment failed: Error launching the VMs. Please contact support."
        )
      end
    end
  end

  context "when the deployment failed without details" do
    let(:deployment) { { id: "dep-1", status: "failed", details: "" } }

    it "reports the ADM status" do
      expect { refresh }.to change { infrastructure.reload.last_error }.to("ADM reported deployment status: failed")
    end
  end

  context "when the deployment was deleted" do
    let(:deployment) { { id: "dep-1", status: "deleted" } }

    before { refresh }

    it "marks the infrastructure destroyed" do
      expect(infrastructure.reload.state).to eq("destroyed")
    end

    it "closes the project item" do
      expect(infrastructure.project_item.reload.status_type).to eq("closed")
    end
  end

  %w[deleting unknown].each do |status|
    context "when the deployment is #{status}" do
      let(:deployment) { { id: "dep-1", status: status } }

      it "only records the state check" do
        refresh
        expect(infrastructure.reload).to have_attributes(state: "creating",
                                                         last_state_check_at: be_within(5.seconds).of(Time.current))
      end
    end
  end

  context "when ADM does not know the deployment" do
    before do
      stub_request(:get, "https://adm.test.example.com/adim/deployment/dep-1").to_return(
        status: 404,
        body: { description: "Deployment not found" }.to_json,
        headers: {
          "Content-Type" => "application/json"
        }
      )
      refresh
    end

    it "marks the infrastructure failed" do
      expect(infrastructure.reload).to have_attributes(state: "failed", last_error: /Deployment not found/)
    end

    it "rejects the project item" do
      expect(infrastructure.project_item.reload.status_type).to eq("rejected")
    end
  end

  context "when ADM is unavailable" do
    before { stub_request(:get, "https://adm.test.example.com/adim/deployment/dep-1").to_return(status: 503) }

    it "raises an error for the polling job to handle" do
      expect { refresh }.to raise_error(Adm::Error)
    end
  end
end
