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

    expect(page).to have_link("Timeline")
    expect(page).to have_link("Contact with service provider")
    expect(page).to have_link("Service Details")
  end

  [:open_access, :external].each do |type|
    scenario "I cannot see timeline for #{type} order" do
      offer = create(:offer, service: service, offer_type: type)
      project_item = create(:project_item, offer: offer, project: project)

      visit project_service_path(project, project_item)

      expect(page).to_not have_link("Timeline")
    end
  end
end
