# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Marketplace version" do
  include OmniauthHelper

  let(:admin) { create(:user, roles: [:admin]) }

  before { checkin_sign_in_as(admin) }

  scenario "can been seen in admin main page" do
    # allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("MP_VERSION").and_return("1234")

    visit admin_path

    expect(page).to have_content("1234")
  end
end
