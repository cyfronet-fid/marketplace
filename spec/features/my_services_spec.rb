# frozen_string_literal: true

require "rails_helper"

RSpec.feature "My Services", end_user_frontend: true do
  include OmniauthHelper

  context "as a logged-in user" do
    let(:user) { create(:user) }
    let(:service) { create(:service) }
    let(:offer) { create(:offer, service: service) }
    let(:project) { create(:project, user: user) }

    before { checkin_sign_in_as(user) }

    scenario "I can only see projects that I own" do
      p1, p2 = create_list(:project, 2, user: user)
      not_owned = create(:project)

      visit projects_path

      expect(page).to have_text(p1.name)
      expect(page).to have_text(p2.name)
      expect(page).to_not have_text(not_owned.name)
    end

    scenario "I can see the services of my project" do
      create(:project_item, project: project, offer: offer)

      visit project_services_path(project)

      expect(page).to have_text(service.name)
    end

    context "project item sections" do
      scenario "I can see order_required section" do
        create(:project_item, project: project, offer: offer)
        visit project_services_path(project)

        expect(page).to have_text("Ordered services")
        expect(page).to_not have_text("Open access services")
        expect(page).to_not have_text("Other services")
      end

      scenario "I can see open_access section with a open_access project item" do
        create(:project_item, project: project, offer: build(:open_access_offer))
        visit project_services_path(project)

        expect(page).to_not have_text("Ordered services")
        expect(page).to have_text("Open access services")
        expect(page).to_not have_text("Other services")
      end

      scenario "I can see open_access section with a fully_open_access project item" do
        create(:project_item, project: project, offer: build(:fully_open_access_offer))
        visit project_services_path(project)

        expect(page).to_not have_text("Ordered services")
        expect(page).to have_text("Open access services")
        expect(page).to_not have_text("Other services")
      end

      scenario "I can see other section with an other project item" do
        create(:project_item, project: project, offer: build(:other_offer))
        visit project_services_path(project)

        expect(page).to_not have_text("Ordered services")
        expect(page).to_not have_text("Open access services")
        expect(page).to have_text("Other services")
      end

      scenario "proper items are in a proper sections" do
        ordered_pi = create(:project_item, project: project, offer: offer)
        open_access_pi = create(:project_item, project: project, offer: build(:open_access_offer))
        fully_open_access_pi = create(:project_item, project: project, offer: build(:fully_open_access_offer))
        other_pi = create(:project_item, project: project, offer: build(:other_offer))

        visit project_services_path(project)

        expect(find(".ordered-resources")).to have_text(ordered_pi.service.name)
        expect(find(".ordered-resources")).to_not have_text(open_access_pi.service.name)
        expect(find(".ordered-resources")).to_not have_text(fully_open_access_pi.service.name)
        expect(find(".ordered-resources")).to_not have_text(other_pi.service.name)

        expect(find(".open-access-resources")).to_not have_text(ordered_pi.service.name)
        expect(find(".open-access-resources")).to have_text(open_access_pi.service.name)
        expect(find(".open-access-resources")).to have_text(fully_open_access_pi.service.name)
        expect(find(".open-access-resources")).to_not have_text(other_pi.service.name)

        expect(find(".other-resources")).to_not have_text(ordered_pi.service.name)
        expect(find(".other-resources")).to_not have_text(open_access_pi.service.name)
        expect(find(".other-resources")).to_not have_text(fully_open_access_pi.service.name)
        expect(find(".other-resources")).to have_text(other_pi.service.name)
      end
    end

    scenario "I can see the project_item details" do
      project_item = create(:project_item, project: project, offer: offer)

      visit project_service_path(project, project_item)

      expect(page).to have_text(project_item.service.name)
    end

    # Test added after hotfix for a bug in `project_items/show.html.haml:30` (v1.2.0)
    scenario "I can see project_item details without a scientific_domain" do
      offer = create(:open_access_offer, service: create(:open_access_service))
      project = create(:project, user: user, scientific_domains: [])
      project_item = create(:project_item, project: project, offer: offer)

      visit project_service_path(project, project_item)

      expect(page).to have_text(project_item.service.name)
    end

    scenario "I cannot see other users' project_items" do
      other_user_project_item = create(:project_item, offer: offer)

      visit project_service_path(other_user_project_item.project, other_user_project_item)

      # TODO: the given service is showing up in Others pane in home view
      # expect(page).to_not have_text(other_user_project_item.service.name)
      expect(page).to have_text("not authorized")
    end

    scenario "I can see the project_item change history", js: true do
      project_item = create(:project_item, project: project, offer: offer)

      project_item.new_status(status: "created", status_type: :created)
      project_item.new_status(status: "registered", status_type: :registered)
      project_item.new_status(status: "ready", status_type: :ready)

      visit project_service_timeline_path(project, project_item)

      expect(page).to have_text("ready")

      expect(page).to have_text(I18n.t("conversations.status.info.created"))
      expect(page).to have_text(I18n.t("conversations.status.info.ready"))
    end

    scenario "I can see voucher id" do
      project_item =
        create(:project_item, project: project, offer: create(:offer, voucherable: true), voucher_id: "V123V")

      visit project_service_path(project, project_item)

      expect(page).to have_text(project_item.voucher_id)
    end

    scenario "I can see voucher id if the voucher is requested and delivered" do
      project_item =
        create(
          :project_item,
          project: project,
          offer: create(:offer, voucherable: true),
          request_voucher: true,
          user_secrets: {
            "voucher_id" => "V123V"
          }
        )

      visit project_service_path(project, project_item)

      expect(page).to have_text("V123V")
    end

    scenario "I cannot see voucher entry" do
      project_item = create(:project_item, project: project, offer: offer)

      visit project_service_path(project, project_item)

      expect(page).to_not have_text("Voucher")
    end

    scenario "I can see that the voucher has been requested" do
      project_item =
        create(:project_item, project: project, offer: create(:offer, voucherable: true), request_voucher: true)

      visit project_service_path(project, project_item)

      expect(page).to have_text("Vouchers\nRequested")
    end

    scenario "I cannot see the review section" do
      project_item = create(:project_item, project: project, offer: offer)

      visit project_service_path(project, project_item)

      expect(page).to_not have_text("Your review")
    end

    scenario "I can see review section" do
      project_item = create(:project_item, project: project, offer: offer, status: "ready", status_type: :ready)
      travel 1.day
      visit project_service_path(project, project_item)

      expect(page).to have_text("Your review")
      expect(page).to have_text("please share your experience so far")
    end

    context "message labels" do
      scenario "I see messages from the fully identified provider" do
        project_item = create(:project_item, project: project, offer: offer)
        provider_message = create(:provider_message, messageable: project_item)

        visit project_service_conversation_path(project, project_item)

        message_label =
          "#{Message.last.created_at.to_fs(:db)}, " \
            "#{provider_message.author_name} " \
            "(#{provider_message.author_email}), Provider"

        expect(page).to have_text(provider_message.message)
        expect(page).to have_text(message_label)
      end

      scenario "I see messages from the provider identified only by name" do
        project_item = create(:project_item, project: project, offer: offer)
        provider_message = create(:provider_message, author_email: nil, messageable: project_item)

        visit project_service_conversation_path(project, project_item)

        message_label =
          "#{Message.last.created_at.to_fs(:db)}, " \
            "#{provider_message.author_name}, Provider"

        expect(page).to have_text(provider_message.message)
        expect(page).to have_text(message_label)
      end

      scenario "I see messages from the provider identified only by email" do
        project_item = create(:project_item, project: project, offer: offer)
        provider_message = create(:provider_message, author_name: nil, messageable: project_item)

        visit project_service_conversation_path(project, project_item)

        message_label =
          "#{Message.last.created_at.to_fs(:db)}, " \
            "#{provider_message.author_email}, Provider"

        expect(page).to have_text(provider_message.message)
        expect(page).to have_text(message_label)
      end

      scenario "I see messages from the anonymous provider" do
        project_item = create(:project_item, project: project, offer: offer)
        provider_message = create(:provider_message, author_name: "", author_email: nil, messageable: project_item)

        visit project_service_conversation_path(project, project_item)

        message_label = "#{Message.last.created_at.to_fs(:db)}, Provider"

        expect(page).to have_text(provider_message.message)
        expect(page).to have_text(message_label)
      end

      scenario "I see label that the message is for my eyes only" do
        project_item = create(:project_item, project: project, offer: offer)
        provider_message = create(:provider_message, scope: "user_direct", messageable: project_item)

        visit project_service_conversation_path(project, project_item)

        expect(page).to have_text(provider_message.message)
        expect(page).to have_text("Visible only to you")
      end
    end

    context "new messages" do
      scenario "question message is mandatory" do
        project_item = create(:project_item, project: project, offer: offer)

        visit project_service_conversation_path(project, project_item)
        click_button "Send message"

        expect(page).to have_text("can't be blank")
        expect(page).to_not have_selector(".new-message-icon")
        expect(page).to_not have_selector(".new-message-separator")
      end

      scenario "I can ask a question about my project_item" do
        project_item = create(:project_item, project: project, offer: offer)

        visit project_service_conversation_path(project, project_item)
        fill_in "message_message", with: "This is my question"
        click_button "Send message"

        expect(page).to have_text("This is my question")
        expect(page).to have_text("You, #{Message.last.created_at.to_fs(:db)}")
        expect(page).to_not have_selector(".new-message-icon")
        expect(page).to_not have_selector(".new-message-separator")
      end

      scenario "I see new message icon if I have some new project item messages" do
        project_item = create(:project_item, project: project, offer: offer)
        create(:provider_message, messageable: project_item)

        visit project_services_path(project)
        expect(page).to_not have_selector(".contact-nav > .new-message-icon")
        expect(page).to have_selector(".project-listing-item > .new-message-icon")
        expect(page).to have_text("You have a new message")
        expect(page).to have_selector(".new-message-icon", count: 2)

        click_link project_item.service.name
        expect(page).to have_selector(".contact-nav > .new-message-icon")
        expect(page).to have_selector(".project-listing-item > .new-message-icon")
        expect(page).to have_selector(".new-message-icon", count: 2)

        click_link "Contact with service provider"
        expect(page).to_not have_selector(".new-message-icon")
        expect(page).to have_selector(".new-message-separator")
      end

      scenario "I see new message separator appearing and disappearing appropriately", js: true do
        project_item = create(:project_item, project: project, offer: offer)
        create(:provider_message, messageable: project_item)

        visit project_service_conversation_path(project, project_item)
        expect(page).to have_selector(".new-message-separator")

        find("#message_message").click
        expect(page).to_not have_selector(".new-message-separator")
      end

      scenario "I don't see the new message icon when I don't have any new project_item messages" do
        project_item = create(:project_item, project: project, offer: offer)

        visit project_service_path(project, project_item)
        expect(page).to_not have_selector(".new-message-icon")

        click_link "Contact with service provider"
        create(:provider_message, messageable: project_item, scope: "internal")

        visit current_path
        expect(page).to_not have_selector(".new-message-icon")
        expect(page).to_not have_selector(".new-message-separator")
      end

      scenario "I don't see the project_item new message label if I don't have any new project_item messages" do
        create(:project_item, project: project, offer: offer)
        project.update(conversation_last_seen: Time.now)
        create(:provider_message, messageable: project)

        visit project_services_path(project)
        expect(page).to have_selector(".contact-nav > .new-message-icon")
        expect(page).to have_selector(".project-listing-item > .new-message-icon")
        expect(page).to have_selector(".new-message-icon", count: 2)
        expect(page).to_not have_text("You have a new message")
      end
    end
  end

  context "as anonymous user" do
    scenario "I don't see 'My projects' page" do
      visit root_path

      expect(page).to_not have_text("My projects")
    end
  end
end
