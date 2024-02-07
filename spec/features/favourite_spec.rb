# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Favourites", end_user_frontend: true, skip: true do
  include OmniauthHelper

  context "JS: As anonymous user" do
    scenario "I can see checkbox set to true in other view", skip: true, js: true do
      # Favourites are currently not used
      service = create(:service)

      visit services_path

      expect(page).to have_text(service.name)
      find("#favourite-#{service.id}", visible: false).click

      # expect(page).to have_text("Save your favourites!")

      service.reload

      visit service_path(service)

      expect(page).to have_text(service.name)
      expect(page.find("#favourite-#{service.id}", visible: false)).to be_checked
    end

    scenario "I can save my favourites by log in", js: true do
      services = create_list(:service, 3)

      user = create(:user)

      visit services_path

      expect(page).to have_text(services[0].name)
      find("#favourite-#{services[0].id}", visible: false).click

      # expect(page).to have_text("Save your favourites!")
      # find("#popup-modal-action-btn").click
      find("#favourite-#{services[2].id}", visible: false).click
      expect(page).to have_text("Remove from favourites")
      expect(page.find("input#favourite-#{services[2].id}", visible: false)).to be_checked

      checkin_sign_in_as(user)
      expect(page).to have_text("Successfully authenticated")

      visit favourites_path

      expect(page).to have_text(services[0].name)
      expect(page).to have_text(services[2].name)
      expect(page).to_not have_text(services[1].name)
    end

    scenario "I cannot remove a resource from favourites if after log in it was my favourite resource", js: true do
      fav1, fav2 = create_list(:service, 2)
      user = create(:user_with_favourites, favourite_services: [fav1, fav2])

      visit services_path

      find("#favourite-#{fav1.id}", visible: false).click

      # find("#popup-modal-action-btn").click
      find("#favourite-#{fav1.id}", visible: false).click

      checkin_sign_in_as(user)

      visit favourites_path

      expect(page).to have_text(fav2.name)
      expect(page).to have_text(fav1.name)
    end
  end

  context "As anonymous user" do
    scenario "I can see favourite checkbox on resource page" do
      service = create(:service)

      visit service_path(service)

      expect(page).to have_content "Add to favourites"
      expect(page).to_not have_content "Remove from favourites"
    end

    scenario "I can see favourite checkbox on resource list page" do
      create_list(:service, 2)

      visit services_path

      expect(page).to have_content "Add to favourites"
      expect(page).to_not have_content "Remove from favourites"
    end
  end

  context "As a regular user" do
    context "on favourites resource page" do
      scenario "I can see it" do
        fav1, fav2 = create_list(:service, 2)
        user = create(:user_with_favourites, favourite_services: [fav1, fav2])

        checkin_sign_in_as(user)

        visit favourites_path

        expect(page).to have_content "Favourite services"
        expect(page).to have_content fav1.name
        expect(page).to have_content fav2.name
      end

      scenario "I can remove resource from favourites", js: true do
        fav1, fav2 = create_list(:service, 2)
        user = create(:user_with_favourites, favourite_services: [fav1, fav2])

        checkin_sign_in_as(user)

        visit favourites_path

        expect(page).to have_content "Favourite services"
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

        expect(page).to have_content "Add to favourites"
      end

      scenario "I can add resource to favourites", js: true do
        Capybara.page.current_window.resize_to("1600", "1024")
        fav1, fav2 = create_list(:service, 2)
        user = create(:user_with_favourites, favourite_services: [fav1])

        checkin_sign_in_as(user)

        visit service_path(fav2)

        expect(page).to have_content "Add to favourites"

        find("#favourite-#{fav2.id}", visible: false).click

        expect(page).to_not have_content "Add to favourites"
        expect(page).to have_content "Remove from favourites"

        visit favourites_path

        expect(page).to have_content fav1.name
        expect(page).to have_content fav2.name
      end

      scenario "I can remove resource from favourites", js: true do
        Capybara.page.current_window.resize_to("1600", "1024")
        fav1, fav2 = create_list(:service, 2)
        user = create(:user_with_favourites, favourite_services: [fav1, fav2])

        checkin_sign_in_as(user)

        visit service_path(fav2)

        expect(page).to have_content "Remove from favourites"

        find("#favourite-#{fav2.id}", visible: false).click

        expect(page).to have_content "Add to favourites"
        expect(page).to_not have_content "Remove from favourites"

        visit favourites_path

        expect(page).to have_content fav1.name
        expect(page).to_not have_content fav2.name
      end
    end

    context "on resource list page" do
      scenario "I can see favourite checkbox", js: true do
        create_list(:service, 2)
        user = create(:user_with_favourites)

        checkin_sign_in_as(user)

        visit services_path

        expect(page).to have_content "Add to favourites"
      end

      scenario "I can add resource to favourites", js: true do
        fav1, fav2 = create_list(:service, 2)
        user = create(:user_with_favourites, favourite_services: [fav1])

        checkin_sign_in_as(user)

        visit services_path

        expect(page).to have_content "Add to favourites"

        find("#favourite-#{fav2.id}", visible: false).click

        visit favourites_path

        expect(page).to have_content fav1.name
        expect(page).to have_content fav2.name
      end

      scenario "I can remove resource from favourites", js: true do
        fav1, fav2 = create_list(:service, 2)
        user = create(:user_with_favourites, favourite_services: [fav1, fav2])

        checkin_sign_in_as(user)

        visit services_path

        expect(page).to have_content "Remove from favourites"

        find("#favourite-#{fav2.id}", visible: false).click

        visit favourites_path

        expect(page).to have_content fav1.name
        expect(page).to_not have_content fav2.name
      end
    end
  end
end
