# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Query param tour", end_user_frontend: true do
  include CookieHelper

  let(:later_cookie_name) { "tours-marketplace-services-show-query_param_1" }

  let(:service) { create(:service) }

  scenario "should display first step even if later cookie is set", js: true do
    set_cookie(later_cookie_name, "later")

    visit service_path(service, tour: "query_param_1")

    expect(page).to have_selector(".shepherd-content")
  end

  scenario "should display first step", js: true do
    visit service_path(service, tour: "query_param_1")

    expect(page).to have_selector(".shepherd-content", visible: true)

    expect(find(".shepherd-footer")).to have_text("Let's take a tour")
    expect(find(".shepherd-footer")).to have_text("I'LL DO IT LATER")

    expect(find(".shepherd-header")).to have_text("qp1-1 title")
    expect(find(".shepherd-text")).to have_text("qp1-1 text")
  end

  scenario "should display second step", js: true do
    visit service_path(service, tour: "query_param_1")

    click_on "Let's take a tour"

    expect(find(".shepherd-header")).to have_text("qp1-2 title")
    expect(find(".shepherd-text")).to have_text("qp1-2 text")
  end

  scenario "should skip tour in first step", js: true do
    visit service_path(service, tour: "query_param_1")

    click_on "I'll do it later"

    expect(page).to have_current_path(service_path(service))
  end

  scenario "should skip tour in second step", js: true do
    visit service_path(service, tour: "query_param_1")

    click_on "Let's take a tour"
    click_on "Skip tour"

    sleep(1)

    expect(page).to have_current_path(service_path(service))
  end

  scenario "should take a full tour", skip: true, js: true do
    # Test is skipped because currently we don't use shepherd for tours
    visit service_path(service, tour: "query_param_1")
    expect(page).to have_selector(".shepherd-content", visible: true)

    click_on "Let's take a tour"
    click_on "Next"

    expect(page).to have_current_path(service_details_path(service, tour: "query_param_2"))

    click_on "Next"
    click_on "Next"

    expect(page).to have_current_path(service_details_path(service))

    expect(page).to have_text("Congratulations!")
    expect(page).to have_text("You have completed the service presentation page tour guide.")
    expect(page).to have_text("Please also leave a comment on how we can improve it")

    click_on "Cancel and end tour"

    expect(page).not_to have_text("Congratulations!")
  end
end
