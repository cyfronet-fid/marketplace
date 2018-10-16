# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Service order" do
  include OmniauthHelper

  context "as logged in user" do

    let(:user) { create(:user) }
    let(:service) { create(:service) }

    before { checkin_sign_in_as(user) }

    scenario "I see order service button" do
      visit service_path(service)

      expect(page).to have_text("Order")
    end

    scenario "I see order open acces service button" do
      @open_access_service = create(:open_access_service)
      visit service_path(@open_access_service)

      expect(page).to have_text("Add to my services")
    end

    scenario "I can add order to cart" do
      visit service_path(service)

      click_button "Order"

      expect(page).to have_current_path(new_order_path)
      expect(page).to have_text(service.title)
      expect(page).to have_selector(:link_or_button,
                                    "Order", exact: true)

      expect { click_on "Order" }.
        to change { Order.count }.by(1)
      order = Order.last

      expect(order.service_id).to eq(service.id)
      expect(page).to have_content(service.title)
    end

    scenario "I can order open acces service" do
      @open_access_service = create(:open_access_service)

      visit service_path(@open_access_service)

      click_button "Add to my services"

      expect(page).to have_current_path(new_order_path)
      expect(page).to have_text(@open_access_service.title)
      expect(page).to have_selector(:link_or_button,
                                    "Order", exact: true)
    end

    scenario "I can see my ordered services" do
      create(:order, user: user, service: service)

      visit orders_path

      expect(page).to have_text(service.title)
    end

    scenario "I can see order details" do
      order = create(:order, user: user, service: service)

      visit order_path(order)

      expect(page).to have_text(order.service.title)
    end

    scenario "I cannot se other users orders" do
      other_user_order = create(:order, service: service)

      visit order_path(other_user_order)

      expect(page).to_not have_text(other_user_order.service.title)
      expect(page).to have_text("not authorized")
    end

    scenario "I can see order change history" do
      order = create(:order, user: user, service: service)

      order.new_change(status: :created, message: "Order created")
      order.new_change(status: :registered, message: "Order registered")
      order.new_change(status: :ready, message: "Order ready")

      visit order_path(order)

      expect(page).to have_text("Current status: ready")

      expect(page).to have_text("Order created")

      expect(page).to have_text("Order changed from created to registered")
      expect(page).to have_text("Order registered")

      expect(page).to have_text("Order changed from registered to ready")
      expect(page).to have_text("Order registered")
    end

    scenario "I can ask question about my order" do
      order = create(:order, user: user, service: service)

      visit order_path(order)
      fill_in "order_question_text", with: "This is my question"
      click_button "Send message"

      expect(page).to have_text("This is my question")
    end

    scenario "question message is mandatory" do
      order = create(:order, user: user, service: service)

      visit order_path(order)
      click_button "Send message"

      expect(page).to have_text("Question cannot be blank")
    end
  end

  context "as anonymous user" do

    scenario "I nead to login to order" do
      service = create(:service)
      user = create(:user)

      visit service_path(service)

      expect(page).to have_selector(:link_or_button, "Order", exact: true)

      click_on "Order"

      checkin_sign_in_as(user)

      expect(page).to have_current_path(new_order_path)
      expect(page).to have_text(service.title)
    end

    scenario "I can see order button" do
      service = create(:service)

      visit service_path(service)

      expect(page).to have_selector(:link_or_button, "Order", exact: true)
    end

    scenario "I can see openaccess service order button" do
      open_access_service =  create(:open_access_service)

      visit service_path(open_access_service)

      expect(page).to have_selector(:link_or_button, "Add to my services", exact: true)
      expect(page).to have_selector(:link_or_button, "Go to the service", exact: true)
    end

    scenario "I don't see my services page" do
      visit root_path

      expect(page).to_not have_text("My services")
    end
  end
end
