# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Service browsing" do
  include OmniauthHelper

  let(:user) { create(:user) }

  before { checkin_sign_in_as(user) }

  scenario "allows to see details" do
    service = create(:service)

    visit service_path(service)

    expect(page.body).to have_content service.title
    expect(page.body).to have_content service.description
    expect(page.body).to have_content service.terms_of_use
  end
end
