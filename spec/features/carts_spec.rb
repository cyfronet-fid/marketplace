# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Cart" do
  include OmniauthHelper

  let(:user) { create(:user) }
  let(:service) { create(:service) }

  before { checkin_sign_in_as(user) }

  scenario "I can create ProjectItem service" do
    visit service_path(service)
    click_on "ProjectItem"

    expect { click_on "ProjectItem" }.
      to change { ProjectItem.count }.by(1)
    project_item = ProjectItem.last

    expect(project_item.service).to eq(service)
    expect(project_item.user).to eq(user)
    expect(project_item).to be_created
    expect(page).to_not have_content("Cart is empty")
  end
end
