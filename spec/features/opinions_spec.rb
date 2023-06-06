# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Service opinions", end_user_frontend: true do
  include OmniauthHelper

  %i[open_access fully_open_access other].each do |type|
    context "for #{type} service" do
      let(:user) { create(:user, first_name: "John", last_name: "Doe") }
      let(:project) { create(:project, user: user) }
      let(:service) { create(:service, order_type: type) }
      let(:offer) { create(:offer, order_type: type, service: service) }
      let(:project_item) { create(:project_item, offer: offer, project: project, status_type: :ready) }

      it "shows user review" do
        create(:service_opinion, project_item: project_item, opinion: "my opinion")

        visit service_opinions_path(service)

        expect(page).to have_content("John")
        expect(page).to have_content("D.")
        expect(page).to have_content("my opinion")
      end

      it "shows correct questions in the opinions form" do
        checkin_sign_in_as(user)
        visit project_service_path(project, project_item)

        click_on "Review service"

        expect(page).to have_content(
          "How satisfied you are with the #{service.name} service on a scale " \
            "of 1 - dissatisfied to 5 - very satisfied?"
        )

        expect(page).to have_content(
          "Was adding the service to the project useful for you on a scale " \
            "of 1 - not useful at all to 5 - very useful?"
        )
      end
    end
  end
  [true, false].each do |internal|
    context "for orderable service" do
      let(:user) { create(:user, first_name: "John", last_name: "Doe") }
      let(:project) { create(:project, user: user) }
      let(:service) { create(:service, order_type: :order_required) }
      let(:offer) { create(:offer, order_type: :order_required, internal: internal, service: service) }
      let(:project_item) { create(:project_item, offer: offer, project: project, status_type: :ready) }

      it "shows correct questions in the opinions form for internal offer" do
        checkin_sign_in_as(user)
        visit project_service_path(project, project_item)

        click_on "Review service"

        expect(page).to have_content(
          "How satisfied you are with the #{service.name} service on a scale " \
            "of 1 - dissatisfied to 5 - very satisfied?"
        )
        if internal
          expect(page).to have_content(
            "How satisfied you are with the ordering process on a scale " + "of 1 - dissatisfied to 5 - very satisfied?"
          )
        else
          expect(page).to have_content(
            "Was adding the service to the project useful for you on a scale " \
              "of 1 - not useful at all to 5 - very useful?"
          )
        end
      end
    end
  end
end
