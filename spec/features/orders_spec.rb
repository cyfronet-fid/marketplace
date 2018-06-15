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
      expect(order.status).to eq("new_order")
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
