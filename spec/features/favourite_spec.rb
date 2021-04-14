# frozen_string_literal: true

require "rails_helper"
require "raven"

RSpec.feature "Favourites" do
  include OmniauthHelper

  context "As anonymous user" do
    scenario "I cannot visit favourites resources page" do
      visit favourites_path

      expect(page).to_not have_content "Favourite resources"
    end

    scenario "I cannot see favourite checkbox on resource page" do
      service = create(:service)

      visit service_path(service)

      expect(page).to_not have_content "Add to favourites"
      expect(page).to_not have_content "Remove from favourites"
    end

    scenario "I cannot see favourite checkbox on resource list page" do
      create_list(:service, 2)

      visit services_path()

      expect(page).to_not have_content "Add to favourites"
      expect(page).to_not have_content "Remove from favourites"
    end
  end

  context "As a regular user" do
    context "on favourites resource page" do
      scenario "I can see it" do
        fav1, fav2 = create_list(:service, 2)
        user = create(:user_with_favourites, favourite_services: [fav1, fav2])

        checkin_sign_in_as(user)

        visit favourites_path()

        expect(page).to have_content "Favourite resources"
        expect(page).to have_content fav1.name
        expect(page).to have_content fav2.name
      end

      scenario "I can remove resource from favourites", js: true do
        fav1, fav2 = create_list(:service, 2)
        user = create(:user_with_favourites, favourite_services: [fav1, fav2])

        checkin_sign_in_as(user)

        visit favourites_path()

        expect(page).to have_content "Favourite resources"
        expect(page).to have_content fav1.name
        expect(page).to have_content fav2.name

        find("#favourite-#{fav1.id}", visible: false).click

        expect(page).to_not have_content fav1.name
        expect(page).to have_content fav2.name
      end
    end

    context "on resource page" do
      scenario "I can see favourite checkbox", js: true do
        Capybara.page.current_window.resize_to("1600", "1024")
        user = create(:user_with_favourites)
        service = create(:service)

        checkin_sign_in_as(user)

        visit service_path(service)
        # close shepherd's tour
        click_on "I'll do it later"
        expect(page).to have_content "Add to favourites"
      end

      scenario "I can add resource to favourites", js: true do
        Capybara.page.current_window.resize_to("1600", "1024")
        fav1, fav2 = create_list(:service, 2)
        user = create(:user_with_favourites, favourite_services: [fav1])

        checkin_sign_in_as(user)

        visit service_path(fav2)
        # close shepherd's tour
        click_on "I'll do it later"

        expect(page).to have_content "Add to favourites"

        find("#favourite-#{fav2.id}", visible: false).click

        expect(page).to_not have_content "Add to favourites"
        expect(page).to have_content "Remove from favourites"

        visit favourites_path()

        expect(page).to have_content fav1.name
        expect(page).to have_content fav2.name
      end

      scenario "I can remove resource from favourites", js: true do
        Capybara.page.current_window.resize_to("1600", "1024")
        fav1, fav2 = create_list(:service, 2)
        user = create(:user_with_favourites, favourite_services: [fav1, fav2])

        checkin_sign_in_as(user)

        visit service_path(fav2)
        # close shepherd's tour
        click_on "I'll do it later"

        expect(page).to have_content "Remove from favourites"

        find("#favourite-#{fav2.id}", visible: false).click

        expect(page).to have_content "Add to favourites"
        expect(page).to_not have_content "Remove from favourites"

        visit favourites_path()

        expect(page).to have_content fav1.name
        expect(page).to_not have_content fav2.name
      end
    end

    context "on resource list page" do
      scenario "I can see favourite checkbox", js: true do
        create_list(:service, 2)
        user = create(:user_with_favourites)

        checkin_sign_in_as(user)

        visit services_path()

        expect(page).to have_content "Add to favourites"
      end

      scenario "I can add resource to favourites", js: true do
        fav1, fav2 = create_list(:service, 2)
        user = create(:user_with_favourites, favourite_services: [fav1])

        checkin_sign_in_as(user)

        visit services_path()

        expect(page).to have_content "Add to favourites"

        find("#favourite-#{fav2.id}", visible: false).click

        visit favourites_path()

        expect(page).to have_content fav1.name
        expect(page).to have_content fav2.name
      end

      scenario "I can remove resource from favourites", js: true do
        fav1, fav2 = create_list(:service, 2)
        user = create(:user_with_favourites, favourite_services: [fav1, fav2])

        checkin_sign_in_as(user)

        visit services_path()

        expect(page).to have_content "Remove from favourites"

        find("#favourite-#{fav2.id}", visible: false).click

        visit favourites_path()

        expect(page).to have_content fav1.name
        expect(page).to_not have_content fav2.name
      end
    end
  end
end
