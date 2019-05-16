# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Project" do
  include OmniauthHelper

  let(:user) { create(:user) }
  before { checkin_sign_in_as(user) }

  scenario "I can create new project" do
    visit projects_path

    click_on "Create new project"

    fill_in "Name", with: "First test"
    fill_in "Reason for access", with: "because I'm testing"
    select "Single user", from: "Customer typology"
    expect { click_on "Create" }.
      to change { user.projects.count }.by(1)
    new_project = Project.last

    expect(new_project.name).to eq("First test")
  end

  scenario "After successful creation new project I'm redirected to projects page" do
    visit projects_path

    click_on "Create new project"

    fill_in "Name", with: "Second test"
    fill_in "Reason for access", with: "because I'm testing"
    select "Single user", from: "Customer typology"
    click_on "Create"

    expect(current_url).to eq(projects_url)
  end
end
