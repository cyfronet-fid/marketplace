# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Project services" do
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

  [:open_access, :external].each do |type|
    scenario "I cannot see timeline for #{type} order" do
      offer = create(:offer, service: service, order_type: type)
      project_item = create(:project_item, offer: offer, project: project)

      visit project_service_path(project, project_item)

      expect(page).to_not have_link("Timeline")
    end
  end

  scenario "Project service is immute to the offer change" do
    offer = create(:offer, service: service,
                   order_type: :open_access,
                   webpage: "http://old.pl",
                   voucherable: false)
    project_item = create(:project_item, offer: offer, project: project)
    offer.update(order_type: :orderable, voucherable: true, webpage: "http://new.pl")

    visit project_service_path(project, project_item)

    expect(page).to have_text("Open")
    expect(page).to_not have_text("Internal ordering")
    expect(page).to have_link("Go to the service", href: "http://old.pl")
    expect(page).to_not have_link("Go to the service", href: "http://new.pl")
  end
end
