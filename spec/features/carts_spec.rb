# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Cart" do
  include OmniauthHelper

  let(:user) { create(:user) }
  let(:service) { create(:service) }

  before { checkin_sign_in_as(user) }

  scenario "I can create Order service" do
    visit service_path(service)
    click_on "Order"

    expect { click_on "Order" }.
      to change { Order.count }.by(1)
    order = Order.last

    expect(order.service).to eq(service)
    expect(order.user).to eq(user)
    expect(order).to be_created
    expect(page).to_not have_content("Cart is empty")
  end
end
