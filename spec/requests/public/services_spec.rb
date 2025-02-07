# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Services" do
  context "as a logged in service portfolio manager" do
    let(:user) { create(:user, roles: [:coordinator]) }
    let(:provider) { create(:provider, data_administrators: [build(:data_administrator, email: user.email)]) }
    before { login_as(user) }

    context "when service has deleted status" do
      it "I can't see a service" do
        service = create(:service, resource_organisation: provider, status: :deleted)

        get service_path(service)
        expect(response).to redirect_to "/404"
      end

      it "I can't see a service with param 'from'" do
        service = create(:service, resource_organisation: provider, status: :deleted)

        get service_path(service, from: "backoffice_service")
        expect(response).to redirect_to "/404"
      end

      it "I can't see a offer" do
        service = create(:service, resource_organisation: provider, status: :deleted)
        offer = create(:offer, service: service)

        get service_offers_path(service, offer)
        expect(response).to redirect_to "/404"
      end

      it "I can't see a offer with param 'from'" do
        service = create(:service, resource_organisation: provider, status: :deleted)
        offer = create(:offer, service: service)

        get service_offers_path(service, offer, from: "backoffice_service")
        expect(response).to redirect_to "/404"
      end

      it "I can't see a configuration" do
        service = create(:service, resource_organisation: provider, status: :deleted)

        get service_configuration_path(service)
        expect(response).to redirect_to "/404"
      end

      it "I can't see a configuration with param 'from'" do
        service = create(:service, resource_organisation: provider, status: :deleted)

        get service_configuration_path(service, from: "backoffice_service")
        expect(response).to redirect_to "/404"
      end

      it "I can't see a information" do
        service = create(:service, resource_organisation: provider, status: :deleted)

        get service_information_path(service)
        expect(response).to redirect_to "/404"
      end

      it "I can't see a information with param 'from'" do
        service = create(:service, resource_organisation: provider, status: :deleted)

        get service_information_path(service, from: "backoffice_service")
        expect(response).to redirect_to "/404"
      end

      it "I can't see a summary" do
        service = create(:service, resource_organisation: provider, status: :deleted)

        get service_summary_path(service)
        expect(response).to redirect_to "/404"
      end

      it "I can't see a summary with param 'from'" do
        service = create(:service, resource_organisation: provider, status: :deleted)

        get service_summary_path(service, from: "backoffice_service")
        expect(response).to redirect_to "/404"
      end

      it "I can't cancel" do
        service = create(:service, resource_organisation: provider, status: :deleted)

        delete service_cancel_path(service)
        expect(response).to redirect_to "/404"
      end

      it "I can't cancel with param 'from'" do
        service = create(:service, resource_organisation: provider, status: :deleted)

        delete service_cancel_path(service, from: "backoffice_service")
        expect(response).to redirect_to "/404"
      end

      it "I can't create a new question" do
        service = create(:service, resource_organisation: provider, status: :deleted)

        get new_service_question_path(service)
        expect(response).to redirect_to "/404"
      end

      it "I can't see the opinions" do
        service = create(:service, resource_organisation: provider, status: :deleted)

        get service_opinions_path(service)
        expect(response).to redirect_to "/404"
      end

      it "I can't see the opinions with param 'from'" do
        service = create(:service, resource_organisation: provider, status: :deleted)

        get service_opinions_path(service)
        expect(response).to redirect_to "/404"
      end

      it "I can't see details" do
        service = create(:service, resource_organisation: provider, status: :deleted)

        get service_details_path(service)
        expect(response).to redirect_to "/404"
      end

      it "I can't see details with param 'from'" do
        service = create(:service, resource_organisation: provider, status: :deleted)

        get service_details_path(service, from: "backoffice_service")
        expect(response).to redirect_to "/404"
      end

      it "I can't see a ordering configuration" do
        service = create(:service, resource_organisation: provider, status: :deleted, offers: [create(:offer)])

        get service_ordering_configuration_path(service)
        expect(response).to redirect_to "/404"
      end

      it "I can't see a ordering configuration with param 'from'" do
        service = create(:service, resource_organisation: provider, status: :deleted, offers: [create(:offer)])

        get service_ordering_configuration_path(service, from: "backoffice_service")
        expect(response).to redirect_to "/404"
      end

      it "I can't create a new offer" do
        service = create(:service, resource_organisation: provider, status: :deleted)

        get new_service_ordering_configuration_offer_path(service)
        expect(response).to redirect_to "/404"
      end

      it "I can't create a new offer with param 'from'" do
        service = create(:service, resource_organisation: provider, status: :deleted)

        get new_service_ordering_configuration_offer_path(service, from: "backoffice_service")
        expect(response).to redirect_to "/404"
      end
    end

    context "when service has draft status" do
      it "I can't see a service" do
        service = create(:service, resource_organisation: provider, status: :draft)

        get service_path(service)
        expect(response).to redirect_to "/404"
      end

      it "I can see a service" do
        service = create(:service, resource_organisation: provider, status: :draft)

        get service_path(service, from: "backoffice_service")
        expect(response).not_to redirect_to "/404"
      end

      it "I can't see a offer" do
        service = create(:service, resource_organisation: provider, status: :draft, offers_count: 1)
        offer = create(:offer, service: service)

        get service_offers_path(service, offer)
        expect(response).to redirect_to "/404"
      end

      it "I can see a offer" do
        service = create(:service, resource_organisation: provider, status: :draft, offers_count: 1)
        offer = create(:offer, service: service)

        get service_offers_path(service, offer, from: "backoffice_service")
        expect(response).not_to redirect_to "/404"
      end

      it "I can't see a configuration" do
        service = create(:service, resource_organisation: provider, status: :draft)

        get service_configuration_path(service)
        expect(response).to redirect_to "/404"
      end

      it "I can see a configuration" do
        service = create(:service, resource_organisation: provider, status: :draft)

        get service_configuration_path(service, from: "backoffice_service")
        expect(response).not_to redirect_to "/404"
      end

      it "I can't see a information" do
        service = create(:service, resource_organisation: provider, status: :draft)

        get service_information_path(service)
        expect(response).to redirect_to "/404"
      end

      it "I can see a information" do
        service = create(:service, resource_organisation: provider, status: :draft)

        get service_information_path(service, from: "backoffice_service")
        expect(response).not_to redirect_to "/404"
      end

      it "I can't see a summary" do
        service = create(:service, resource_organisation: provider, status: :draft)

        get service_summary_path(service)
        expect(response).to redirect_to "/404"
      end

      it "I can see a summary" do
        service = create(:service, resource_organisation: provider, status: :draft)

        get service_summary_path(service, from: "backoffice_service")
        expect(response).not_to redirect_to "/404"
      end

      it "I can't cancel" do
        service = create(:service, resource_organisation: provider, status: :draft)

        delete service_cancel_path(service)
        expect(response).to redirect_to "/404"
      end

      it "I can cancel" do
        service = create(:service, resource_organisation: provider, status: :draft)

        delete service_cancel_path(service, from: "backoffice_service")
        expect(response).not_to redirect_to "/404"
      end

      it "I can't create a new question" do
        service = create(:service, resource_organisation: provider, status: :draft)

        get new_service_question_path(service, format: :js)
        expect(response).to redirect_to "/404"
      end

      it "I can't see the opinions" do
        service = create(:service, resource_organisation: provider, status: :draft)

        get service_opinions_path(service)
        expect(response).to redirect_to "/404"
      end

      it "I can't see the opinions" do
        service = create(:service, resource_organisation: provider, status: :draft)

        get service_opinions_path(service, from: "backoffice_service")
        expect(response).not_to redirect_to "/404"
      end

      it "I can't see details" do
        service = create(:service, resource_organisation: provider, status: :draft)

        get service_details_path(service)
        expect(response).to redirect_to "/404"
      end

      it "I can see details" do
        service = create(:service, resource_organisation: provider, status: :draft)

        get service_details_path(service, from: "backoffice_service")
        expect(response).not_to redirect_to "/404"
      end

      it "I can't see a ordering configuration" do
        service = create(:service, resource_organisation: provider, status: :draft, offers: [create(:offer)])

        get service_ordering_configuration_path(service)
        expect(response).to redirect_to "/404"
      end

      it "I can't see a ordering configuration" do
        service = create(:service, resource_organisation: provider, status: :draft, offers: [create(:offer)])

        get service_ordering_configuration_path(service, from: "backoffice_service")
        expect(response).not_to redirect_to "/404"
      end

      it "I can't create a new offer" do
        service = create(:service, resource_organisation: provider, status: :draft)

        get new_service_ordering_configuration_offer_path(service)
        expect(response).to redirect_to "/404"
      end

      it "I can create a new offer" do
        service = create(:service, resource_organisation: provider, status: :draft)

        get new_service_ordering_configuration_offer_path(service, from: "backoffice_service")
        expect(response).not_to redirect_to "/404"
      end
    end
  end

  context "as a logged in user" do
    let(:user) { create(:user) }
    before { login_as(user) }

    context "when service has deleted status" do
      it "I can't see a service" do
        service = create(:service, status: :deleted)

        get service_path(service)
        expect(response).to redirect_to "/404"
      end

      it "I can't see a offer" do
        service = create(:service, status: :deleted)
        offer = create(:offer, service: service)

        get service_offers_path(service, offer)
        expect(response).to redirect_to "/404"
      end

      it "I can't see a configuration" do
        service = create(:service, status: :deleted)

        get service_configuration_path(service)
        expect(response).to redirect_to "/404"
      end

      it "I can't see a information" do
        service = create(:service, status: :deleted)

        get service_information_path(service)
        expect(response).to redirect_to "/404"
      end

      it "I can't see a summary" do
        service = create(:service, status: :deleted)

        get service_summary_path(service)
        expect(response).to redirect_to "/404"
      end

      it "I can't cancel" do
        service = create(:service, status: :deleted)

        delete service_cancel_path(service)
        expect(response).to redirect_to "/404"
      end

      it "I can't create a new question" do
        service = create(:service, status: :deleted)

        get new_service_question_path(service, format: :js)
        expect(response).to redirect_to "/404"
      end

      it "I can't see the opinions" do
        service = create(:service, status: :deleted)

        get service_opinions_path(service)
        expect(response).to redirect_to "/404"
      end

      it "I can't see details" do
        service = create(:service, status: :deleted)

        get service_details_path(service)
        expect(response).to redirect_to "/404"
      end

      it "I can't see a ordering configuration" do
        service = create(:service, status: :deleted, offers: [create(:offer)])

        get service_ordering_configuration_path(service)
        expect(response).to redirect_to "/404"
      end

      it "I can't create a new offer" do
        service = create(:service, status: :deleted)

        get new_service_ordering_configuration_offer_path(service)
        expect(response).to redirect_to "/404"
      end
    end

    context "when service has draft status" do
      it "I can't see a service" do
        service = create(:service, status: :draft)

        get service_path(service)
        expect(response).to redirect_to "/404"
      end

      it "I can't see a offer" do
        service = create(:service, status: :draft)
        offer = create(:offer, service: service)

        get service_offers_path(service, offer)
        expect(response).to redirect_to "/404"
      end

      it "I can't see a configuration" do
        service = create(:service, status: :draft)

        get service_configuration_path(service)
        expect(response).to redirect_to "/404"
      end

      it "I can't see a information" do
        service = create(:service, status: :draft)

        get service_information_path(service)
        expect(response).to redirect_to "/404"
      end

      it "I can't see a summary" do
        service = create(:service, status: :draft)

        get service_summary_path(service)
        expect(response).to redirect_to "/404"
      end

      it "I can't cancel" do
        service = create(:service, status: :draft)

        delete service_cancel_path(service)
        expect(response).to redirect_to "/404"
      end

      it "I can't create a new question" do
        service = create(:service, status: :draft)

        get new_service_question_path(service, format: :js)
        expect(response).to redirect_to "/404"
      end

      it "I can't see the opinions" do
        service = create(:service, status: :draft)

        get service_opinions_path(service)
        expect(response).to redirect_to "/404"
      end

      it "I can't see details" do
        service = create(:service, status: :draft)

        get service_details_path(service)
        expect(response).to redirect_to "/404"
      end

      it "I can't see a ordering configuration" do
        service = create(:service, status: :draft, offers: [create(:offer)])

        get service_ordering_configuration_path(service)
        expect(response).to redirect_to "/404"
      end

      it "I can't create a new offer" do
        service = create(:service, status: :draft)

        get new_service_ordering_configuration_offer_path(service)
        expect(response).to redirect_to "/404"
      end
    end
  end
end
