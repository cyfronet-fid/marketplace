# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Marketplace version", manager_frontend: true do
  include OmniauthHelper

  let(:admin) { create(:user, roles: [:admin]) }
  let(:version) { File.read(Rails.root.join("VERSION")).strip }

  before { checkin_sign_in_as(admin) }

  scenario "is visible in admin main page" do
    visit admin_path

    expect(page).to have_content(version)
  end

  scenario "is read from MP_VERSION constant" do
    stub_const("MP_VERSION", "foo:bar")

    visit admin_path

    expect(page).to have_content("foo:bar")
  end
end
