# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Project services", end_user_frontend: true do
  include OmniauthHelper

  let(:user) { create(:user) }
  let(:project) { create(:project, user: user) }
  let(:service) { create(:service) }

  before { checkin_sign_in_as(user) }

  scenario "I can see additional tabs on project service view for ordered service" do
    offer = create(:offer, service: service)
    project_item = create(:project_item, offer: offer, project: project)

    visit project_service_path(project, project_item)

    expect(page).to have_link("Order history")
    expect(page).to have_link("Contact with service provider")
    expect(page).to have_link("Details")
  end

  context "#created_at display" do
    scenario "The label reads 'Order date' for orderable project_item" do
      offer = create(:offer, service: service)
      project_item = create(:project_item, offer: offer, project: project)

      visit project_service_path(project, project_item)

      expect(page).to have_text("Order date:")
    end

    scenario "The label reads 'Added to the project' for external project_item" do
      offer = create(:external_offer, service: service)
      project_item = create(:project_item, offer: offer, project: project)

      visit project_service_path(project, project_item)

      expect(page).to have_text("Added to the project:")
    end

    scenario "The label reads 'Added to the project' for open_access project_item" do
      service.update(order_type: :open_access)
      offer = create(:open_access_offer, service: service)
      project_item = create(:project_item, offer: offer, project: project)

      visit project_service_path(project, project_item)

      expect(page).to have_text("Added to the project:")
    end
  end

  scenario "I cannot see timeline for open_access order" do
    service.update(order_type: :open_access)
    offer = create(:open_access_offer, service: service)
    project_item = create(:project_item, offer: offer, project: project)

    visit project_service_path(project, project_item)

    expect(page).to_not have_link("Timeline")
  end

  scenario "I cannot see timeline for external order" do
    offer = create(:external_offer, service: service)
    project_item = create(:project_item, offer: offer, project: project)

    visit project_service_path(project, project_item)

    expect(page).to_not have_link("Timeline")
  end

  context "with DeployableService-backed project items" do
    let(:deployable_service) { create(:deployable_service) }

    scenario "I can see the project index page with DeployableService items" do
      offer = create(:offer, deployable_service: deployable_service, order_type: :open_access)
      create(:project_item, offer: offer, project: project, order_type: "open_access")

      visit project_services_path(project)

      expect(page).to have_text(deployable_service.name)
    end

    scenario "I can see the project index page with mixed Service and DeployableService items" do
      service_offer = create(:offer, service: service)
      ds_offer = create(:offer, deployable_service: deployable_service, order_type: :open_access)
      create(:project_item, offer: service_offer, project: project)
      create(:project_item, offer: ds_offer, project: project, order_type: "open_access")

      visit project_services_path(project)

      expect(page).to have_text(service.name)
      expect(page).to have_text(deployable_service.name)
    end

    scenario "recommended offers work when project has only DeployableService items" do
      ds_with_domains = create(:deployable_service, :with_scientific_domains)
      offer = create(:offer, deployable_service: ds_with_domains, order_type: :open_access)
      create(:project_item, offer: offer, project: project, order_type: "open_access")

      expect { visit project_services_path(project) }.not_to raise_error
      expect(page).to have_text("Recommended offers for your project")
    end
  end

  scenario "Project service is immutable to the offer change" do
    create(:offer, service: service)
    offer = create(:offer, service: service, order_type: :open_access, order_url: "http://old.pl", voucherable: false)
    project_item = create(:project_item, offer: offer, project: project)
    offer.update(order_type: :order_required, voucherable: true, order_url: "http://new.pl")

    visit project_service_path(project, project_item)

    expect(page).to have_text("Open")
    expect(page).to_not have_text("Internal ordering")
    expect(page).to have_link("Go to the service", href: "http://old.pl")
    expect(page).to_not have_link("Go to the service", href: "http://new.pl")
  end
end
