# frozen_string_literal: true

require "rails_helper"

RSpec.describe Infrastructure, type: :model do
  let(:provider) { create(:provider) }
  let(:deployable_service) { create(:deployable_service, resource_organisation: provider) }
  let(:service_category) { create(:service_category) }
  let(:offer) { create(:offer, service: nil, deployable_service: deployable_service, offer_category: service_category) }
  let(:project) { create(:project) }
  let(:project_item) { create(:project_item, offer: offer, project: project) }

  let(:infrastructure) do
    Infrastructure.create!(
      project_item: project_item,
      im_base_url: "https://deploy.sandbox.eosc-beyond.eu",
      cloud_site: "IISAS-FedCloud",
      state: "pending"
    )
  end

  # Helper to create additional project items for scope tests
  def create_project_item_for_infra
    create(:project_item, offer: offer, project: project)
  end

  describe "validations" do
    it "is valid with valid attributes" do
      expect(infrastructure).to be_valid
    end

    it "requires project_item" do
      infra = Infrastructure.new(im_base_url: "https://example.com", cloud_site: "test", state: "pending")
      expect(infra).not_to be_valid
      expect(infra.errors[:project_item]).to be_present
    end

    it "requires im_base_url" do
      infra = Infrastructure.new(project_item: project_item, cloud_site: "test", state: "pending")
      expect(infra).not_to be_valid
      expect(infra.errors[:im_base_url]).to include("can't be blank")
    end

    it "requires cloud_site" do
      infra = Infrastructure.new(project_item: project_item, im_base_url: "https://example.com", state: "pending")
      expect(infra).not_to be_valid
      expect(infra.errors[:cloud_site]).to include("can't be blank")
    end

    it "requires state to be a valid value" do
      infra =
        Infrastructure.new(
          project_item: project_item,
          im_base_url: "https://example.com",
          cloud_site: "test",
          state: "invalid_state"
        )
      expect(infra).not_to be_valid
      expect(infra.errors[:state]).to be_present
    end

    it "allows all valid states" do
      Infrastructure::STATES.each do |valid_state|
        infra =
          Infrastructure.new(
            project_item: project_item,
            im_base_url: "https://example.com",
            cloud_site: "test",
            state: valid_state
          )
        expect(infra).to be_valid, "Expected state '#{valid_state}' to be valid"
      end
    end

    it "enforces uniqueness of im_infrastructure_id" do
      infrastructure.update!(im_infrastructure_id: "unique-id-123")

      project_item2 = create(:project_item, offer: offer, project: project)
      duplicate =
        Infrastructure.new(
          project_item: project_item2,
          im_base_url: "https://example.com",
          cloud_site: "test",
          state: "pending",
          im_infrastructure_id: "unique-id-123"
        )
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:im_infrastructure_id]).to be_present
    end

    it "allows nil im_infrastructure_id" do
      expect(infrastructure.im_infrastructure_id).to be_nil
      expect(infrastructure).to be_valid
    end
  end

  describe "associations" do
    it "belongs to project_item" do
      expect(infrastructure.project_item).to eq(project_item)
    end

    it "can access deployable_service through project_item" do
      expect(infrastructure.deployable_service).to eq(deployable_service)
    end
  end

  describe "scopes" do
    describe ".active" do
      it "excludes destroyed and failed infrastructures, includes others" do
        pending_infra = infrastructure
        running_infra =
          Infrastructure.create!(
            project_item: create_project_item_for_infra,
            im_base_url: "https://example.com",
            cloud_site: "test",
            state: "running"
          )

        # Check active scope
        active_ids = Infrastructure.active.pluck(:id)
        expect(active_ids).to include(pending_infra.id, running_infra.id)

        # Now mark one as destroyed and one as failed
        running_infra.update_column(:state, "destroyed")
        pending_infra.update_column(:state, "failed")

        # Re-check - they should be excluded now
        active_ids = Infrastructure.active.pluck(:id)
        expect(active_ids).not_to include(running_infra.id)
        expect(active_ids).not_to include(pending_infra.id)
      end
    end

    describe ".pending_state_check" do
      it "includes active infrastructures needing state check" do
        old_check =
          Infrastructure.create!(
            project_item: create_project_item_for_infra,
            im_base_url: "https://example.com",
            cloud_site: "test",
            state: "running",
            last_state_check_at: 2.minutes.ago
          )
        never_checked = infrastructure # has nil last_state_check_at

        pending_ids = Infrastructure.pending_state_check.pluck(:id)
        expect(pending_ids).to include(old_check.id, never_checked.id)
      end

      it "excludes recently checked infrastructures" do
        recently_checked =
          Infrastructure.create!(
            project_item: create_project_item_for_infra,
            im_base_url: "https://example.com",
            cloud_site: "test",
            state: "running",
            last_state_check_at: 30.seconds.ago
          )

        expect(Infrastructure.pending_state_check.pluck(:id)).not_to include(recently_checked.id)
      end

      it "excludes destroyed infrastructures" do
        destroyed =
          Infrastructure.create!(
            project_item: create_project_item_for_infra,
            im_base_url: "https://example.com",
            cloud_site: "test",
            state: "running",
            last_state_check_at: 2.minutes.ago
          )
        destroyed.update_column(:state, "destroyed")

        expect(Infrastructure.pending_state_check.pluck(:id)).not_to include(destroyed.id)
      end
    end
  end

  describe "state predicates" do
    Infrastructure::STATES.each do |state_name|
      describe "##{state_name}?" do
        it "returns true when state is #{state_name}" do
          infrastructure.state = state_name
          expect(infrastructure.send("#{state_name}?")).to be true
        end

        it "returns false when state is not #{state_name}" do
          other_state = (Infrastructure::STATES - [state_name]).first
          infrastructure.state = other_state
          expect(infrastructure.send("#{state_name}?")).to be false
        end
      end
    end
  end

  describe "state transition methods" do
    describe "#mark_created!" do
      it "sets im_infrastructure_id and state to creating" do
        infrastructure.mark_created!("infra-123")
        expect(infrastructure.im_infrastructure_id).to eq("infra-123")
        expect(infrastructure.state).to eq("creating")
        expect(infrastructure.last_state_check_at).to be_present
      end
    end

    describe "#mark_configured!" do
      it "sets state to configured" do
        infrastructure.mark_configured!
        expect(infrastructure.state).to eq("configured")
        expect(infrastructure.last_state_check_at).to be_present
      end
    end

    describe "#mark_running!" do
      it "sets state to running with outputs" do
        outputs = { "jupyterhub_url" => "https://example.com/jupyter" }
        infrastructure.mark_running!(outputs)
        expect(infrastructure.state).to eq("running")
        expect(infrastructure.outputs).to eq(outputs)
        expect(infrastructure.last_error).to be_nil
      end

      it "clears last_error when marking running" do
        infrastructure.update!(last_error: "previous error")
        infrastructure.mark_running!
        expect(infrastructure.last_error).to be_nil
      end
    end

    describe "#mark_failed!" do
      it "sets state to failed with error message" do
        infrastructure.mark_failed!("Something went wrong")
        expect(infrastructure.state).to eq("failed")
        expect(infrastructure.last_error).to eq("Something went wrong")
      end

      it "increments retry_count" do
        expect { infrastructure.mark_failed!("error") }.to change { infrastructure.retry_count }.by(1)
      end
    end

    describe "#mark_destroyed!" do
      it "sets state to destroyed" do
        infrastructure.update_columns(im_infrastructure_id: "infra-123", state: "running")
        infrastructure.mark_destroyed!
        expect(infrastructure.reload.state).to eq("destroyed")
        expect(infrastructure.last_state_check_at).to be_present
      end
    end
  end

  describe "#update_state_from_im!" do
    it "maps 'pending' to creating" do
      infrastructure.update_state_from_im!("pending")
      expect(infrastructure.state).to eq("creating")
    end

    it "maps 'configured' to configured" do
      infrastructure.update_state_from_im!("configured")
      expect(infrastructure.state).to eq("configured")
    end

    it "maps 'running' to running" do
      infrastructure.update_state_from_im!("running")
      expect(infrastructure.state).to eq("running")
    end

    it "maps 'stopped' to running (infrastructure still exists)" do
      infrastructure.update_state_from_im!("stopped")
      expect(infrastructure.state).to eq("running")
    end

    it "maps 'failed' to failed with error" do
      infrastructure.update_state_from_im!("failed")
      expect(infrastructure.state).to eq("failed")
      expect(infrastructure.last_error).to include("failed")
    end

    it "handles case-insensitive states" do
      infrastructure.update_state_from_im!("RUNNING")
      expect(infrastructure.state).to eq("running")
    end

    it "handles unknown states gracefully" do
      expect(Rails.logger).to receive(:warn).with(/Unknown IM state/)
      infrastructure.update_state_from_im!("unknown_state")
      expect(infrastructure.last_state_check_at).to be_present
    end
  end

  describe "#can_destroy?" do
    it "returns true for running infrastructure with im_infrastructure_id" do
      infrastructure.update!(state: "running", im_infrastructure_id: "infra-123")
      expect(infrastructure.can_destroy?).to be true
    end

    it "returns true for failed infrastructure with im_infrastructure_id" do
      infrastructure.update!(state: "failed", im_infrastructure_id: "infra-123")
      expect(infrastructure.can_destroy?).to be true
    end

    it "returns false for destroyed infrastructure" do
      infrastructure.update_columns(state: "destroyed", im_infrastructure_id: "infra-123")
      expect(infrastructure.can_destroy?).to be false
    end

    it "returns false without im_infrastructure_id" do
      infrastructure.update!(state: "running", im_infrastructure_id: nil)
      expect(infrastructure.can_destroy?).to be false
    end

    it "returns false for pending infrastructure" do
      infrastructure.update!(state: "pending", im_infrastructure_id: "infra-123")
      expect(infrastructure.can_destroy?).to be false
    end
  end

  describe "#deployment_url" do
    it "returns jupyterhub_url from outputs" do
      infrastructure.update!(outputs: { "jupyterhub_url" => "https://jupyter.example.com" })
      expect(infrastructure.deployment_url).to eq("https://jupyter.example.com")
    end

    it "falls back to public_url" do
      infrastructure.update!(outputs: { "public_url" => "https://public.example.com" })
      expect(infrastructure.deployment_url).to eq("https://public.example.com")
    end

    it "falls back to endpoint" do
      infrastructure.update!(outputs: { "endpoint" => "https://endpoint.example.com" })
      expect(infrastructure.deployment_url).to eq("https://endpoint.example.com")
    end

    it "returns nil when no URL outputs" do
      infrastructure.update!(outputs: {})
      expect(infrastructure.deployment_url).to be_nil
    end
  end
end
