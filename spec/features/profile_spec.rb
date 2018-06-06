# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Profile page" do
  include OmniauthHelper

  scenario "User can see his profile" do
    user = create(:user)

    checkin_sign_in_as(user)

    expect(page.body).to have_selector("#navbarSupportedContent li.nav-item a.nav-link", text: "My profile")
  
    click_link('My profile')

    expect(page.body).to have_text(user.first_name)
    expect(page.body).to have_text(user.last_name)
    expect(page.body).to have_text(user.email)
  end

  scenario "Unauthenticated user doesn't see navbar link to profile" do
    visit root_path
    
    expect(page.body).to have_no_selector("#navbarSupportedContent li.nav-item a.nav-link", text: "My profile")
  end

  scenario "Unauthenticated user is redirected to checkin" do
    visit profile_path
    
    expect(page).to have_current_path(user_checkin_omniauth_authorize_path) 
  end
end


