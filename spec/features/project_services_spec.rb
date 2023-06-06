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
