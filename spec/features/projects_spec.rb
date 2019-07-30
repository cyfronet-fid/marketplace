# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Project" do
  include OmniauthHelper

  let(:user) { create(:user) }

  context "As logged in user" do
    let(:project_create) { double("Project::Create") }
    let(:project_archive) { double("Project::Archive") }
    before { checkin_sign_in_as(user) }
    before(:each) {
      project_create_class_stub = class_double(Project::Create).
          as_stubbed_const(transfer_nested_constants: true)
      allow(project_create_class_stub).to receive(:new).and_return(project_create)

      project_archive_class_stub = class_double(Project::Archive).
          as_stubbed_const(transfer_nested_constants: true)
      allow(project_archive_class_stub).to receive(:new).and_return(project_archive)
    }

    scenario "I can create new project" do
      visit projects_path

      click_on "Create new project"

      expect(project_create).to receive(:call)
      fill_in "project_name", with: "First test"
      select "Single user", from: "Customer typology"
      fill_in "Email", with: "john@doe.com"
      fill_in "Reason to request access to the EOSC services", with: "because I'm testing"
      select "non-European", from: "Origin country"
      fill_in "Organization", with: "Home corp."
      fill_in "Webpage", with: "http://home.corp.com"

      expect { click_on "Create" }.
        to change { user.projects.count }.by(1)
      new_project = Project.last

      expect(new_project.name).to eq("First test")
    end

    scenario "After successful creation new project I'm redirected to projects page" do
      visit projects_path

      click_on "Create new project"

      expect(project_create).to receive(:call)

      fill_in "project_name", with: "Second test"
      fill_in "Email", with: "john@doe.com"
      fill_in "Reason to request access to the EOSC services", with: "because I'm testing"
      select "non-European", from: "Origin country"
      select "Single user", from: "Customer typology"
      fill_in "Organization", with: "Home corp."
      fill_in "Webpage", with: "http://home.corp.com"
      click_on "Create"

      expect(current_url).to eq(project_url(Project.last))
    end

    scenario "I can create project duplicate" do
      allow(project_create).to receive(:call)
      project = create(:project, user: user)

      visit new_project_path(source: project.id)

      fill_in "Project name", with: "Copy", match: :first
      expect { click_on "Create" }.
        to change { user.projects.count }.by(1)
      new_project = Project.last

      expect(new_project.name).to eq("Copy")
      expect(new_project.reason_for_access).to eq(project.reason_for_access)
      expect(new_project.issue_key).to be_nil
      expect(new_project).to be_jira_uninitialized
    end

    scenario "I cannot use other user project as duplicate source" do
      project = create(:project)

      visit new_project_path(source: project.id)

      fill_in "Project name", with: "Copy", match: :first
      expect { click_on "Create" }.to_not change { user.projects.count }
    end

    scenario "I can edit project" do
      project = create(:project, name: "First Project", user: user)
      visit project_path(project)

      click_on "Edit"

      fill_in "project_name", with: "Edited First Project"

      click_on "Update"

      expect(current_url).to eq(project_url(project))
      expect(page).to have_text(project.name)
    end

    scenario "I cannot update project with invalid fields" do
      project = create(:project, name: "First Project", user: user)

      visit project_path(project)

      click_on "Edit"

      fill_in "project_name", with: ""

      click_on "Update"

      expect(page).to have_text("Name can't be blank")
      expect(page.status_code).to eq(400)
    end

    scenario "I can delete project without any project_item" do
      project = create(:project, name: "First Project", user: user)

      visit project_path(project)

      expect { click_on "Delete" }.
        to change { user.projects.count }.by(-1)
    end

    scenario "I cannot delete project with project_item" do
      project = create(:project, name: "First Project", user: user)
      service = create(:open_access_service)
      offer = create(:offer, service: service)

      create(:project_item, offer: offer, project: project)

      visit project_path(project)

      expect(page).to_not have_selector(:link_or_button, "Delete")
    end

    scenario "I cannot see not my projects" do
      project = create(:project)

      visit project_path(project)

      expect(page).to have_text("You are not authorized to see this page")
    end

    scenario "I cannot see archive button when are no services" do
      project = create(:project, name: "First Project", user: user)

      visit project_path(project)

      expect(page).to_not have_selector(:link_or_button, "Archive")
    end

    scenario "I see archive button when all project_items are ended" do
      project = create(:project, name: "First Project", user: user)
      service = create(:open_access_service)
      offer = create(:offer, service: service)

      create(:project_item, offer: offer, project: project, status: :closed)

      visit project_path(project)

      expect(page).to have_selector(:link_or_button, "Archive")
    end

    scenario "I cannot see archive button when all project_items are not ended" do
      project = create(:project, name: "First Project", user: user)
      service = create(:open_access_service)
      create(:offer, service: service)

      visit project_path(project)

      expect(page).to_not have_selector(:link_or_button, "Archive")
    end

    scenario "I can archive service when all project_items are ended" do
      project = create(:project, name: "First Project", user: user)
      service = create(:service)

      expect(project_archive).to receive(:call)

      offer = create(:offer, service: service)
      create(:project_item, offer: offer, project: project, status: :closed)

      visit project_path(project)
      click_on "Archive"

      expect(page).to have_content("Project archived")
    end
  end

  context "As anonymous user" do
    scenario "I cannot visit My projects" do
      visit root_path

      expect(page.body).to have_no_selector("nav", text: "My projects")
    end
  end
end
