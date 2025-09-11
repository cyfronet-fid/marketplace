# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectItem::Create, backend: true do
  let(:user) { create(:user) }
  let(:project) { create(:project, user: user) }
  let(:service) { create(:service) }
  let(:offer) { create(:offer, service: service, order_type: service.order_type) }
  let(:project_item_template) { build(:customizable_project_item, project: project, offer: offer) }

  it "creates project_item and set initial project_item status" do
    project_item = described_class.new(project_item_template).call

    expect(project_item).to be_created
    expect(project_item.user).to eq(user)
    expect(project_item.service).to eq(service)
  end

  it "creates first project_item status" do
    project_item = described_class.new(project_item_template).call

    expect(project_item.status).to eq("created")
    expect(project_item).to be_created
    expect(project_item.statuses.count).to eq(1)
    expect(project_item.statuses.first.status).to eq("created")
    expect(project_item.statuses.first).to be_created
  end

  it "triggers register project_item in external system" do
    project_item = described_class.new(project_item_template).call

    non_customizable_project_item = ProjectItem.find_by(id: project_item.id)
    expect(ProjectItem::RegisterJob).to have_been_enqueued.with(non_customizable_project_item, nil)
  end

  context "for service with :eosc_registry upstream" do
    let(:service) { create(:service, pid: "foo") }
    let(:upstream) { build(:eosc_registry_service_source) }

    before do
      upstream.update!(service: service)
      service.update!(upstream: upstream)
    end

    it "enqueues publish jobs" do
      described_class.new(project_item_template).call

      expect(Jms::PublishJob).to have_been_enqueued.with(hash_including(message_type: "project.resource_addition"))
      expect(Jms::PublishJob).to have_been_enqueued.with(hash_including(message_type: "project.resource_coexistence"))
    end
  end

  it "doesn't enqueue publish jobs" do
    described_class.new(project_item_template).call

    expect(Jms::PublishJob).not_to have_been_enqueued.with(hash_including(:message_type))
  end

  context "when open_access service has been added to Project" do
    let(:service) { create(:open_access_service) }

    it "sends email to project_item owner - added to the project" do
      expect { described_class.new(project_item_template).call }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end
  end

  context "when external service has been added to Project" do
    let(:service) { create(:external_service) }

    it "sends email to project_item owner - added to the project" do
      expect { described_class.new(project_item_template).call }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end
  end

  context "when orderable service has been ordered" do
    it "sends email to project_item owner" do
      expect { described_class.new(project_item_template).call }.to change { ActionMailer::Base.deliveries.count }.by(1)
    end
  end

  context "#bundle" do
    let(:offer) { create(:offer, service: service) }
    let(:child1) { build(:offer) }
    let(:child2) { build(:offer) }
    let(:bundle) { create(:bundle, service: service, offers: [child1, child2]) }

    let(:project_item_template) { build(:project_item, project: project, offer: offer, bundle: bundle) }

    it "creates bundled project_items" do
      expect { described_class.new(project_item_template, "test-msg", bundle_params: {}).call }.to change {
        ActionMailer::Base.deliveries.count
      }.by(3).and change { ProjectItem.count }.by(3)

      ProjectItem.all.each do |project_item|
        expect(ProjectItem::RegisterJob).to have_been_enqueued.with(project_item, "test-msg")
      end
    end

    context "with error" do
      let(:child2) { build(:offer_with_parameters) }

      it "creates nothing" do
        expect { described_class.new(project_item_template, "test-msg", bundle_params: {}).call }.to change {
          ActionMailer::Base.deliveries.count
        }.by(0).and change { ProjectItem.count }.by(0)

        expect(ProjectItem::RegisterJob).not_to have_been_enqueued
      end
    end
  end

  describe "DeployableService support" do
    let(:provider) { create(:provider) }
    let(:deployable_service) { create(:deployable_service, resource_organisation: provider) }
    let(:service_category) { create(:service_category) }
    let(:ds_offer) do
      create(
        :offer,
        service: nil,
        deployable_service: deployable_service,
        order_type: "order_required",
        offer_category: service_category
      )
    end
    let(:ds_project_item_template) { build(:customizable_project_item, project: project, offer: ds_offer) }

    context "when offer belongs to DeployableService" do
      it "creates project_item with in_progress status for deployment" do
        project_item = described_class.new(ds_project_item_template).call

        expect(project_item).to be_in_progress
        expect(project_item.status).to eq("Deployment in progress")
        expect(project_item.status_type).to eq("in_progress")
      end

      it "skips JIRA registration for DeployableService offers" do
        described_class.new(ds_project_item_template).call

        # Should not enqueue RegisterJob for DeployableService offers
        expect(ProjectItem::RegisterJob).not_to have_been_enqueued
      end

      it "sends emails for DeployableService offers" do
        expect { described_class.new(ds_project_item_template).call }.to change {
          ActionMailer::Base.deliveries.count
        }.by(2) # ProjectItem::Create + DeploymentJob

        # Two emails are sent: one by ProjectItem::Create and one by DeploymentJob
      end

      it "handles DeployableService parent_service correctly" do
        project_item = described_class.new(ds_project_item_template).call

        expect(project_item.offer.parent_service).to eq(deployable_service)
        expect(project_item.offer.service).to be_nil
        expect(project_item.offer.deployable_service).to eq(deployable_service)
      end

      it "creates status records correctly for DeployableService" do
        project_item = described_class.new(ds_project_item_template).call

        expect(project_item.statuses.count).to eq(2) # created -> in_progress
        expect(project_item.statuses.first.status).to eq("created")
        expect(project_item.statuses.last.status).to eq("Deployment in progress")
      end

      context "with TOSCA template processing (TODO comment)" do
        it "includes TODO for TOSCA template processing" do
          # This test documents the TODO mentioned in line 62
          project_item = described_class.new(ds_project_item_template).call

          expect(project_item).to be_in_progress
          # TODO: When TOSCA template processing is implemented, add specs here
          # expect(ToscaTemplateProcessingJob).to have_been_enqueued.with(project_item)
        end
      end
    end

    context "when offer has mixed DeployableService and Service behavior" do
      let(:regular_service) { create(:service) }
      let(:regular_offer) { create(:offer, service: regular_service, order_type: "order_required") }
      let(:regular_project_item_template) { build(:customizable_project_item, project: project, offer: regular_offer) }

      it "handles DeployableService offers differently from Service offers" do
        # Create both types
        ds_project_item = described_class.new(ds_project_item_template).call
        service_project_item = described_class.new(regular_project_item_template).call

        # DeployableService offer should be in_progress
        expect(ds_project_item.status).to eq("Deployment in progress")
        expect(ds_project_item).to be_in_progress

        # Service offer should be created
        expect(service_project_item.status).to eq("created")
        expect(service_project_item).to be_created

        # Different job enqueueing
        expect(ProjectItem::RegisterJob).to have_been_enqueued.with(ProjectItem.find(service_project_item.id), nil)
        expect(ProjectItem::RegisterJob).not_to have_been_enqueued.with(ProjectItem.find(ds_project_item.id), nil)
      end
    end

    context "with non-orderable DeployableService offers" do
      let(:non_orderable_ds_offer) do
        create(
          :offer,
          service: nil,
          deployable_service: deployable_service,
          order_type: "open_access",
          offer_category: service_category
        )
      end
      let(:non_orderable_ds_template) do
        build(:customizable_project_item, project: project, offer: non_orderable_ds_offer)
      end

      it "handles non-orderable DeployableService offers correctly" do
        project_item = described_class.new(non_orderable_ds_template).call

        # Should still be handled as DeployableService (in_progress status)
        expect(project_item.status).to eq("Deployment in progress")
        expect(project_item).to be_in_progress

        # Should still skip JIRA registration
        expect(ProjectItem::RegisterJob).not_to have_been_enqueued
        expect(ProjectItemMailer).to have_received(:added_to_project)
      end
    end

    context "with bundles containing DeployableService offers" do
      let(:ds_child1) do
        create(:offer, service: nil, deployable_service: deployable_service, offer_category: service_category)
      end
      let(:ds_child2) do
        create(:offer, service: nil, deployable_service: deployable_service, offer_category: service_category)
      end
      let(:ds_bundle) { create(:bundle, service: deployable_service, offers: [ds_child1, ds_child2]) }
      let(:ds_bundle_template) { build(:project_item, project: project, offer: ds_offer, bundle: ds_bundle) }

      it "creates bundled DeployableService project_items with ready status" do
        expect { described_class.new(ds_bundle_template, "test-msg", bundle_params: {}).call }.to change {
          ProjectItem.count
        }.by(3) # main + 2 bundled

        # All project items should be in_progress (DeployableService handling)
        ProjectItem
          .where(bundle: ds_bundle)
          .each do |project_item|
            expect(project_item.status).to eq("Deployment in progress")
            expect(project_item).to be_in_progress
          end

        # Should not enqueue RegisterJob for any DeployableService offers
        expect(ProjectItem::RegisterJob).not_to have_been_enqueued
      end

      it "sends correct emails for bundled DeployableService offers" do
        email_count_before = ActionMailer::Base.deliveries.count

        described_class.new(ds_bundle_template, "test-msg", bundle_params: {}).call

        # Should send added_to_project emails (3 total: main + 2 bundled)
        expect(ActionMailer::Base.deliveries.count).to eq(email_count_before + 3)

        # Verify all are added_to_project emails, not created emails
        ProjectItem
          .where(bundle: ds_bundle)
          .each { |project_item| expect(ProjectItemMailer).to have_received(:added_to_project).with(project_item) }
      end
    end

    context "error handling with DeployableService offers" do
      it "handles transaction rollback correctly for DeployableService" do
        # Force an error during project_item creation
        allow_any_instance_of(ProjectItem).to receive(:update).and_return(false)

        project_item = described_class.new(ds_project_item_template).call

        # Should not have persisted due to rollback
        expect(project_item).not_to be_persisted
        expect(ProjectItemMailer).not_to have_received(:added_to_project)
      end

      it "handles notify_providers correctly for DeployableService with limited availability" do
        # Create limited availability DeployableService offer
        limited_ds_offer =
          create(
            :offer,
            service: nil,
            deployable_service: deployable_service,
            limited_availability: true,
            availability_count: 1,
            offer_category: service_category
          )
        limited_template = build(:customizable_project_item, project: project, offer: limited_ds_offer)

        # Create data administrator for the provider
        admin_user = create(:user)
        create(:data_administrator, provider: provider, user: admin_user)

        # This should reduce availability to 0 and trigger notification
        described_class.new(limited_template).call

        limited_ds_offer.reload
        if limited_ds_offer.availability_count.zero?
          expect(OfferMailer).to have_received(:notify_provider).with(limited_ds_offer, admin_user)
        end
      end
    end

    context "integration with project publication" do
      it "triggers project publication events for DeployableService offers" do
        allow(ProjectItem::OnCreated::PublishAddition).to receive(:call)
        allow(ProjectItem::OnCreated::PublishCoexistence).to receive(:call)

        project_item = described_class.new(ds_project_item_template).call

        updated_project = Project.find(project.id)
        expect(ProjectItem::OnCreated::PublishAddition).to have_received(:call).with(
          updated_project,
          [ProjectItem.find(project_item.id)]
        )
        expect(ProjectItem::OnCreated::PublishCoexistence).to have_received(:call).with(updated_project)
      end
    end

    context "compatibility with existing Service workflow" do
      it "maintains backward compatibility with Service offers while adding DeployableService support" do
        regular_service = create(:service)
        regular_offer = create(:offer, service: regular_service, order_type: "order_required")
        regular_template = build(:customizable_project_item, project: project, offer: regular_offer)

        # Both should work without interfering with each other
        ds_project_item = described_class.new(ds_project_item_template).call
        service_project_item = described_class.new(regular_template).call

        # DeployableService: ready status, no RegisterJob
        expect(ds_project_item.status).to eq("ready")
        expect(ProjectItem::RegisterJob).not_to have_been_enqueued.with(ProjectItem.find(ds_project_item.id), nil)

        # Regular Service: created status, RegisterJob enqueued
        expect(service_project_item.status).to eq("created")
        expect(ProjectItem::RegisterJob).to have_been_enqueued.with(ProjectItem.find(service_project_item.id), nil)
      end
    end
  end
end
