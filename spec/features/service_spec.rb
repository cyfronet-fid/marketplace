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

  scenario "terms of use is rendered from markdown to html" do
    service = create(:service, terms_of_use: "# Terms of use h1")

    visit service_path(service)

    expect(page.body).to match(/<h1>Terms of use h1/)
  end
end
