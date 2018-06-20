# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Service order" do


  context "as logged in user" do
    include OmniauthHelper

    let(:user) { create(:user) }
    let(:service) { create(:service) }

    before { checkin_sign_in_as(user) }

    scenario "I see order service button" do
      visit service_path(service)

      expect(page).to have_text("Order")
    end

    scenario "I can order service" do
      visit service_path(service)

      expect { click_button "Order" }.
        to change { Order.count }.by(1)
      order = Order.last

      expect(order.service).to eq(service)
      expect(order.user).to eq(user)
      expect(order).to be_created
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

      order.new_change(:created, "Order created")
      order.new_change(:registered, "Order registered")
      order.new_change(:ready, "Order ready")

      visit order_path(order)

      expect(page).to have_text("Current status: ready")

      expect(page).to have_text("Order created")

      expect(page).to have_text("Order changed from created to registered")
      expect(page).to have_text("Order registered")

      expect(page).to have_text("Order changed from registered to ready")
      expect(page).to have_text("Order registered")
    end
  end

  context "as anonymous user" do
    scenario "I don't see order button" do
      service = create(:service)

      visit service_path(service)

      expect(page).to_not have_text("Order")
    end

    scenario "I don't my services page" do
      visit root_path

      expect(page).to_not have_text("My services")
    end
  end
end
