# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Service tour" do
  include CookieHelper

  LATER_COOKIE_NAME = "tours-marketplace-services-show-service_about_intro"

  let(:service) { create(:service) }

  scenario "shouldn't display first step if later cookie is set", js: true do
    set_cookie(LATER_COOKIE_NAME, "later")

    visit service_path(service)

    expect(page).not_to have_selector(".shepherd-content")
  end

  scenario "should display first step", js: true do
    visit service_path(service)

    expect(page).to have_selector(".shepherd-content", visible: true)

    expect(find(".shepherd-footer")).to have_text("Let's take a tour")
    expect(find(".shepherd-footer")).to have_text("I'LL DO IT LATER")

    expect(find(".shepherd-header")).to have_text("New resource presentation layout!")
    expect(find(".shepherd-text")).to have_text("The resources shown in the EOSC Portal come from a wide variety")
  end

  scenario "should display second step", js: true do
    visit service_path(service)

    click_on "Let's take a tour"

    expect(find(".shepherd-header")).to have_text("Main section")
    expect(find(".shepherd-text")).to have_text("The main section of the resource presentation page highlights the")
  end

  scenario "should skip tour in first step", js: true do
    visit service_path(service)

    click_on "I'll do it later"

    expect(cookie(LATER_COOKIE_NAME)[:value]).to eq("later")
  end

  scenario "should skip tour in second step", js: true do
    visit service_path(service)

    click_on "Let's take a tour"
    click_on "Skip tour"

    expect(cookie(LATER_COOKIE_NAME)[:value]).to eq("later")
  end

  scenario "should take a full tour", js: true do
    visit service_path(service)
    expect(page).to have_selector(".shepherd-content", visible: true)

    click_on "Let's take a tour"
    click_on "Next"
    click_on "Next"
    click_on "Next"
    click_on "Next"

    expect(page).to have_current_path(service_details_path(service))
    expect(cookie("tours-marketplace-services-show-completed")[:value]).to eq("[%22service_about_intro%22]")

    click_on "Next"
    click_on "Next"

    expect(page).to have_text("Congratulations!")
    expect(page).to have_text("You have completed the resource presentation page tour guide.")
    expect(page).to have_text("Please also leave a comment on how we can improve it")

    expect(cookie("tours-marketplace-details-index-completed")[:value]).to eq("[%22service_details_intro%22]")

    click_on "Cancel and end tour"

    expect(page).not_to have_text("Congratulations!")
  end
end
