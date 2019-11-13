# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Add project item to project" do
  include OmniauthHelper

  let(:user) { create(:user) }
  let(:service) { create(:service) }

  before { checkin_sign_in_as(user) }

  scenario "Project is selected when item is ordered from project view" do
    service = create(:open_access_service)
    create(:offer, service: service)
    project = create(:project, user: user, name: "my fancy project")

    visit project_services_path(project)
    click_on "Add your first service"

    visit service_information_path(service)
    click_on "Next", match: :first
    click_on "Next", match: :first

    expect(page).to have_select("project_item_project_id",
                                selected: "my fancy project")
  end
end
