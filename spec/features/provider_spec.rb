# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Service provider" do
  include OmniauthHelper

  let(:user) { create(:user) }

  before { checkin_sign_in_as(user) }

  scenario "show services for Provider 1" do
    prov1, prov2 = create_list(:provider, 2)

    s1 = create(:service, provider: prov1)
    s2 = create(:service, provider: prov1)
    s3 = create(:service, provider: prov1)
    other_service = create(:service, provider: prov2)

    visit provider_path(prov1)

    expect(page.body).to have_content s1.title
    expect(page.body).to have_content s2.title
    expect(page.body).to have_content s3.title
    expect(page.body).to_not have_content other_service.title
  end
end
