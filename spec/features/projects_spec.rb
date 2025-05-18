# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Project", end_user_frontend: true do
  include OmniauthHelper

  let(:user) { create(:user) }

  context "As a logged-in user" do
    let(:project_create) { double("Project::Create") }
    before { checkin_sign_in_as(user) }

    scenario "I can create a new project" do
      visit projects_path

      click_on "Create new project"

      fill_in "project_name", with: "First test"
      select "Single user", from: "User type"
      fill_in "Project overview", with: "testing testing testing"
      fill_in "Affiliated organisation", with: "Home corp."

      expect { click_on "Create" }.to change { user.projects.count }.by(1)
      new_project = Project.last

      expect(new_project.name).to eq("First test")
    end

    scenario "Scientific domains are displayed as a nested tree" do
      parent = create(:scientific_domain)
      child = create(:scientific_domain, parent: parent)

      visit projects_path

      click_on "Create new project"

      expect(page).to have_content(parent.name)
      expect(page).to have_content("#{parent.name} ⇒ #{child.name}")
    end

    scenario "I can see the services of my first project when entering 'My projects'" do
      project = create(:project, user: user)
      service = create(:service, name: "The best service ever")
      offer = create(:offer, service: service)
      create(:project_item, offer: offer, project: project)

      visit projects_path

      expect(page).to have_text("The best service ever")
    end

    scenario "I'm redirected to projects page after the successful creation of a new project" do
      visit projects_path

      click_on "Create new project"

      fill_in "project_name", with: "Second test"
      fill_in "Project overview", with: "testing testing testing"
      select "Single user", from: "User type"
      click_on "Create"

      expect(current_url).to eq(project_url(Project.last))
    end

    scenario "I can create a duplicate of a project" do
      allow(project_create).to receive(:call)
      project = create(:project, user: user)

      visit new_project_path(source: project.id)

      fill_in "Project name", with: "Copy", match: :first
      expect { click_on "Create" }.to change { user.projects.count }.by(1)
      new_project = Project.last

      expect(new_project.name).to eq("Copy")
      expect(new_project.reason_for_access).to eq(project.reason_for_access)
      expect(new_project.issue_key).to be_nil
      expect(new_project.scientific_domains).to eq(project.scientific_domains)
      expect(new_project).to be_jira_uninitialized
    end

    scenario "I cannot use other user's project as a duplicate source" do
      project = create(:project)

      visit new_project_path(source: project.id)

      fill_in "Project name", with: "Copy", match: :first
      expect { click_on "Create" }.to_not(change { user.projects.count })
    end

    scenario "I can edit a project" do
      project = create(:project, name: "First Project", user: user)
      visit project_path(project)

      click_on "Edit"

      fill_in "project_name", with: "Edited First Project"

      click_on "Update"

      expect(current_url).to eq(project_url(project))
      expect(page).to have_text(project.name)
    end

    scenario "I cannot update the project with invalid fields" do
      project = create(:project, name: "First Project", user: user)

      visit project_path(project)

      click_on "Edit"

      fill_in "project_name", with: ""

      click_on "Update"

      expect(page).to have_text("can't be blank")
      expect(page.status_code).to eq(400)
    end

    scenario "I can delete a project without any project items" do
      project = create(:project, name: "First Project", user: user)

      visit project_path(project)

      expect { click_on "Delete" }.to change { user.projects.count }.by(-1)
    end

    scenario "I cannot delete a project with a project item" do
      project = create(:project, name: "First Project", user: user)
      service = create(:open_access_service)
      offer = create(:open_access_offer, service: service)

      create(:project_item, offer: offer, project: project)

      visit project_path(project)

      expect(page).to_not have_selector(:link_or_button, "Delete")
    end

    scenario "I cannot see projects that I do not own" do
      project = create(:project)

      visit project_path(project)

      expect(page).to have_text("You are not authorized to see this page")
    end

    context "archive" do
      let(:project_archive) { double("Project::Archive") }

      before(:each) do
        project_archive_class_stub = class_double(Project::Archive).as_stubbed_const(transfer_nested_constants: true)
        allow(project_archive_class_stub).to receive(:new).and_return(project_archive)
      end

      scenario "I cannot see the archive button when there are no services" do
        project = create(:project, name: "First Project", user: user)

        visit project_path(project)

        expect(page).to_not have_selector(:link_or_button, "Archive")
      end

      scenario "I can see the archive button when all project_items have a 'closed' status" do
        project = create(:project, name: "First Project", user: user)
        service = create(:open_access_service)
        offer = create(:open_access_offer, service: service)

        create(:project_item, offer: offer, project: project, status: "closed", status_type: :closed)

        visit project_path(project)

        expect(page).to have_selector(:link_or_button, "Archive")
      end

      scenario "I cannot see the archive button while there is a project item that is not 'closed'" do
        project = create(:project, name: "First Project", user: user)
        service = create(:open_access_service)
        create(:open_access_offer, service: service)

        visit project_path(project)

        expect(page).to_not have_selector(:link_or_button, "Archive")
      end

      scenario "I can see the archived status after archivization" do
        project = create(:project, name: "First Project", user: user)
        service = create(:open_access_service)
        offer = create(:open_access_offer, service: service)

        create(:project_item, offer: offer, project: project, status: "closed", status_type: :closed)

        allow(project_archive).to receive(:call).and_return(true)

        visit project_path(project)

        click_on "Archive"
        expect(page).to have_text("Project archived")
      end
    end

    context "message labels" do
      scenario "I see messages from the fully identified mediator" do
        project = create(:project, user: user)
        mediator_message = create(:mediator_message, messageable: project)

        visit project_conversation_path(project)

        message_label =
          "#{Message.last.created_at.to_fs(:db)}, " \
            "#{mediator_message.author_name} " \
            "(#{mediator_message.author_email}), Customer service"

        expect(page).to have_text(mediator_message.message)
        expect(page).to have_text(message_label)
      end

      scenario "I see messages from the mediator identified by name" do
        project = create(:project, user: user)
        mediator_message = create(:mediator_message, author_email: nil, messageable: project)

        visit project_conversation_path(project)

        message_label =
          "#{Message.last.created_at.to_fs(:db)}, " \
            "#{mediator_message.author_name}, Customer service"

        expect(page).to have_text(mediator_message.message)
        expect(page).to have_text(message_label)
      end

      scenario "I see messages from the mediator identified by email" do
        project = create(:project, user: user)
        mediator_message = create(:mediator_message, author_name: nil, messageable: project)

        visit project_conversation_path(project)

        message_label =
          "#{Message.last.created_at.to_fs(:db)}, " \
            "#{mediator_message.author_email}, Customer service"

        expect(page).to have_text(mediator_message.message)
        expect(page).to have_text(message_label)
      end

      scenario "I see messages from the anonymous mediator" do
        project = create(:project, user: user)
        mediator_message = create(:mediator_message, author_name: nil, author_email: "", messageable: project)

        visit project_conversation_path(project)

        message_label = "#{Message.last.created_at.to_fs(:db)}, Customer service"

        expect(page).to have_text(mediator_message.message)
        expect(page).to have_text(message_label)
      end

      scenario "I see label that the message is for my eyes only" do
        project = create(:project, user: user)
        provider_message = create(:mediator_message, scope: "user_direct", messageable: project)

        visit project_conversation_path(project)

        expect(page).to have_text(provider_message.message)
        expect(page).to have_text("Visible only to you")
      end
    end

    context "new messages" do
      scenario "question message is mandatory" do
        project = create(:project, user: user)

        visit project_conversation_path(project)
        click_button "Send message"

        expect(page).to have_text("can't be blank")
        expect(page).to_not have_selector(".new-message-icon")
        expect(page).to_not have_selector(".new-message-separator")
      end

      scenario "I can have a question for the project support" do
        project = create(:project, user: user)
        visit project_conversation_path(project)
        fill_in "message_message", with: "This is my question"
        click_button "Send message"

        expect(page).to have_text("This is my question")
        expect(page).to have_text("You, #{Message.last.created_at.to_fs(:db)}")
        expect(page).to_not have_selector(".new-message-separator")
        expect(page).to_not have_selector(".new-message-icon")
      end

      scenario "I see new message icon when I have new messages" do
        project = create(:project, user: user)
        create(:provider_message, messageable: project)

        visit project_path(project)
        expect(page).to have_selector(".contact-nav > .new-message-icon")
        expect(page).to have_selector(".project-listing-item > .new-message-icon")
        expect(page).to have_selector(".new-message-icon", count: 2)

        click_link "Contact with EOSC experts"
        expect(page).to_not have_selector(".new-message-icon")
        expect(page).to have_selector(".new-message-separator")

        create(:provider_message, messageable: project)
        visit project_path(project)
        expect(page).to have_selector(".contact-nav > .new-message-icon")
        expect(page).to have_selector(".project-listing-item > .new-message-icon")
        expect(page).to have_selector(".new-message-icon", count: 2)
      end

      scenario "I don't see the new message icon when I don't have any new messages" do
        project = create(:project, user: user)

        visit project_services_path(project)
        expect(page).to_not have_selector(".new-message-icon")

        click_link "Contact with EOSC experts"
        create(:provider_message, messageable: project, scope: "internal")

        visit current_path
        expect(page).to_not have_selector(".new-message-icon")
        expect(page).to_not have_selector(".new-message-separator")
      end

      scenario "I new message separator appears and disappears accordingly", js: true do
        project = create(:project, user: user)
        create(:provider_message, messageable: project)

        visit project_conversation_path(project)
        expect(page).to have_selector(".new-message-separator")

        find("#message_message").click
        expect(page).to_not have_selector(".new-message-separator")
      end
    end
  end

  context "As anonymous user" do
    scenario "I cannot visit 'My projects'" do
      visit root_path

      expect(page.body).to have_no_selector("nav", text: "My projects")
    end
  end
end
