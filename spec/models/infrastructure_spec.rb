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
      api_base_url: "https://deploy.sandbox.eosc-beyond.eu",
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
      infra = Infrastructure.new(api_base_url: "https://example.com", cloud_site: "test", state: "pending")
      expect(infra).not_to be_valid
      expect(infra.errors[:project_item]).to be_present
    end

    it "requires api_base_url" do
      infra = Infrastructure.new(project_item: project_item, cloud_site: "test", state: "pending")
      expect(infra).not_to be_valid
      expect(infra.errors[:api_base_url]).to include("can't be blank")
    end

    it "requires cloud_site" do
      infra = Infrastructure.new(project_item: project_item, api_base_url: "https://example.com", state: "pending")
      expect(infra).not_to be_valid
      expect(infra.errors[:cloud_site]).to include("can't be blank")
    end

    it "requires state to be a valid value" do
      infra =
        Infrastructure.new(
          project_item: project_item,
          api_base_url: "https://example.com",
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
            api_base_url: "https://example.com",
            cloud_site: "test",
            state: valid_state
          )
        expect(infra).to be_valid, "Expected state '#{valid_state}' to be valid"
      end
    end

    it "enforces uniqueness of deployment_id" do
      infrastructure.update!(deployment_id: "unique-id-123")

      project_item2 = create(:project_item, offer: offer, project: project)
      duplicate =
        Infrastructure.new(
          project_item: project_item2,
          api_base_url: "https://example.com",
          cloud_site: "test",
          state: "pending",
          deployment_id: "unique-id-123"
        )
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:deployment_id]).to be_present
    end

    it "allows nil deployment_id" do
      expect(infrastructure.deployment_id).to be_nil
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
            api_base_url: "https://example.com",
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

    describe ".adm_managed" do
      it "includes only infrastructures with an ADM allocation" do
        adm_infra =
          Infrastructure.create!(
            project_item: create_project_item_for_infra,
            api_base_url: "https://example.com",
            cloud_site: "test",
            state: "running",
            allocation_id: "alloc-1"
          )

        expect(Infrastructure.adm_managed.pluck(:id)).to contain_exactly(adm_infra.id)
      end
    end

    describe ".pending_state_check" do
      it "includes active infrastructures needing state check" do
        old_check =
          Infrastructure.create!(
            project_item: create_project_item_for_infra,
            api_base_url: "https://example.com",
            cloud_site: "test",
            state: "running",
            allocation_id: "alloc-1",
            last_state_check_at: 2.minutes.ago
          )
        never_checked = infrastructure # has nil last_state_check_at
        never_checked.update!(allocation_id: "alloc-1")

        pending_ids = Infrastructure.pending_state_check.pluck(:id)
        expect(pending_ids).to include(old_check.id, never_checked.id)
      end

      it "excludes legacy infrastructures without an ADM allocation" do
        legacy =
          Infrastructure.create!(
            project_item: create_project_item_for_infra,
            api_base_url: "https://example.com",
            cloud_site: "test",
            state: "running",
            last_state_check_at: 2.minutes.ago
          )

        expect(Infrastructure.pending_state_check.pluck(:id)).not_to include(legacy.id)
      end

      it "excludes recently checked infrastructures" do
        recently_checked =
          Infrastructure.create!(
            project_item: create_project_item_for_infra,
            api_base_url: "https://example.com",
            cloud_site: "test",
            state: "running",
            allocation_id: "alloc-1",
            last_state_check_at: 30.seconds.ago
          )

        expect(Infrastructure.pending_state_check.pluck(:id)).not_to include(recently_checked.id)
      end

      it "excludes destroyed infrastructures" do
        destroyed =
          Infrastructure.create!(
            project_item: create_project_item_for_infra,
            api_base_url: "https://example.com",
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
      it "sets deployment_id and state to creating" do
        infrastructure.mark_created!("infra-123")
        expect(infrastructure.deployment_id).to eq("infra-123")
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
        infrastructure.update_columns(deployment_id: "infra-123", state: "running")
        infrastructure.mark_destroyed!
        expect(infrastructure.reload.state).to eq("destroyed")
        expect(infrastructure.last_state_check_at).to be_present
      end
    end
  end

  describe "#can_destroy?" do
    it "returns true for running infrastructure with deployment_id" do
      infrastructure.update!(state: "running", deployment_id: "infra-123", allocation_id: "alloc-1")
      expect(infrastructure.can_destroy?).to be true
    end

    it "returns true for failed infrastructure with deployment_id" do
      infrastructure.update!(state: "failed", deployment_id: "infra-123", allocation_id: "alloc-1")
      expect(infrastructure.can_destroy?).to be true
    end

    it "returns false for a legacy IM infrastructure without allocation_id" do
      infrastructure.update!(state: "running", deployment_id: "infra-123", allocation_id: nil)
      expect(infrastructure.can_destroy?).to be false
    end

    it "returns false for destroyed infrastructure" do
      infrastructure.update_columns(state: "destroyed", deployment_id: "infra-123")
      expect(infrastructure.can_destroy?).to be false
    end

    it "returns false without deployment_id" do
      infrastructure.update!(state: "running", deployment_id: nil)
      expect(infrastructure.can_destroy?).to be false
    end

    it "returns false for pending infrastructure" do
      infrastructure.update!(state: "pending", deployment_id: "infra-123")
      expect(infrastructure.can_destroy?).to be false
    end
  end

  describe "#deployment_url" do
    it "returns the URL from the stored outputs" do
      infrastructure.update!(outputs: { "jupyterhub_url" => "https://jupyter.example.com" })
      expect(infrastructure.deployment_url).to eq("https://jupyter.example.com")
    end

    it "returns nil when no URL outputs" do
      infrastructure.update!(outputs: {})
      expect(infrastructure.deployment_url).to be_nil
    end

    it "returns the first URL output in template declaration order after reload" do
      infrastructure.update!(
        outputs: { "notebook_url" => "https://notebook.vm.fedcloud.eu/", "admin_url" => "https://admin.example.com/" },
        output_names: %w[admin_url notebook_url]
      )
      expect(infrastructure.reload.deployment_url).to eq("https://admin.example.com/")
    end
  end
end
