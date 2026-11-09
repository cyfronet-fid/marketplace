# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Matomo browser tracking" do
  # An error page or a redirect has no events either; fail instead of passing.
  let(:page) do
    raise "#{request.path} answered #{response.status}" unless response.ok?

    response.parsed_body
  end
  let(:meta_tags) { page.css("meta[name^='matomo-']").to_h { |tag| [tag["name"], tag["content"]] } }
  let(:events) do
    page.css("[data-matomo-event]").map do |element|
      %w[category action name value].index_with { |key| element["data-matomo-#{key}"] }.compact
    end
  end

  before do
    stub_request(:post, %r{/similar_services/recommendation}).to_return(
      status: 200,
      body: { recommendations: [] }.to_json,
      headers: { "Content-Type" => "application/json" }
    )
  end

  shared_context "with an offer added to a project" do
    let(:offer) { create(:offer) }
    let(:project) { create(:project) }

    before do
      allow(Checkin::CheckVoMembership).to receive(:call).and_return(
        Checkin::CheckVoMembership::CheckResult.new(status: :member)
      )
      sign_in(project.user)
      put service_choose_offer_path(offer.service), params: { customizable_project_item: { offer_id: offer.iid } }
      post service_summary_path(offer.service), params: { customizable_project_item: { project_id: project.id } }
    end
  end

  shared_context "with a rated project item" do
    let(:project_item) { create(:project_item, status: "ready", status_type: :ready) }

    before do
      sign_in(project_item.project.user)
      post project_service_opinion_path(project_item.project, project_item),
           params: { service_opinion: { service_rating: 4, order_rating: 5, opinion: "Works well" } }
    end
  end

  context "when Matomo is on" do
    before do
      allow(Mp::Application.config).to receive(:matomo).and_return(
        Matomo::Configuration.new(
          "MP_MATOMO_ENABLED" => "true",
          "MP_MATOMO_URL" => "https://matomo.example.org",
          "MP_MATOMO_SITE_ID" => "12"
        )
      )
    end

    it "gives pages the Matomo URL and site ID" do
      get providers_path

      expect(meta_tags).to eq("matomo-url" => "https://matomo.example.org/", "matomo-site-id" => "12")
    end

    context "with a service page" do
      let(:service) { create(:service) }

      before { get service_path(service) }

      it "carries the View event of the service" do
        expect(events).to eq(["category" => "Service", "action" => "View", "name" => service.pid])
      end

      it "hides the event element" do
        expect(page.at_css("[data-matomo-event]")["hidden"]).to eq("hidden")
      end
    end

    context "with a datasource page" do
      let(:datasource) { create(:datasource) }

      before { get service_path(datasource) }

      it "carries the View event of a service" do
        expect(events).to eq(["category" => "Service", "action" => "View", "name" => datasource.pid])
      end
    end

    context "with a provider page" do
      let(:provider) { create(:provider) }

      before { get provider_path(provider) }

      it "carries the View event of the provider" do
        expect(events).to eq(["category" => "Provider", "action" => "View", "name" => provider.pid])
      end
    end

    context "with a bundle page" do
      let(:bundle) { create(:bundle, service: create(:service, pid: "21.T15999/service-1"), iid: 3) }

      before { get service_bundle_path(bundle.service, bundle.iid) }

      it "carries the View event of the bundle, named by the service PID and the bundle iid" do
        expect(events).to eq(["category" => "Bundle", "action" => "View", "name" => "21.T15999/service-1:3"])
      end
    end

    context "with the offers page of a service" do
      let(:offer) { create(:offer, status: :published) }

      before { get service_offers_path(offer.service) }

      it "carries no event" do
        expect(events).to be_empty
      end
    end

    context "with a deployable service page", variant: :marketplace do
      let(:deployable_service) { create(:deployable_service) }

      before { get deployable_service_path(deployable_service) }

      it "carries no event" do
        expect(events).to be_empty
      end
    end

    context "with the page after adding an offer to a project" do
      include_context "with an offer added to a project"

      before { follow_redirect! }

      it "carries the AddToProject event of the service" do
        expect(events).to eq(["category" => "Service", "action" => "AddToProject", "name" => offer.service.pid])
      end

      it "shows no alert for the event" do
        expect(page.css("[role=alert]").map { |alert| alert.text.strip }).to eq(["Offer ordered successfully"])
      end

      it "keeps the event out of Turbo's page cache, so going back to the page does not send it again" do
        expect(page.at_css("[data-matomo-event]").key?("data-turbo-temporary")).to be(true)
      end
    end

    context "with the page after rating a service" do
      include_context "with a rated project item"

      before { follow_redirect! }

      it "carries the Rate event of the service, with the rating as the value" do
        expect(events).to eq(
          ["category" => "Service", "action" => "Rate", "name" => project_item.service.pid, "value" => "4"]
        )
      end
    end

    context "with the page after rating a deployable service without a PID", variant: :marketplace do
      include_context "with a rated project item" do
        let(:project_item) do
          create(
            :project_item,
            offer: create(:offer, deployable_service: create(:deployable_service, pid: nil)),
            status: "ready",
            status_type: :ready
          )
        end
      end

      before { follow_redirect! }

      it "carries no event, as there is no PID to name it by" do
        expect(events).to be_empty
      end
    end
  end

  context "when Matomo is off" do
    before do
      allow(Mp::Application.config).to receive(:matomo).and_return(
        Matomo::Configuration.new("MP_MATOMO_ENABLED" => "false")
      )
    end

    it "gives pages no Matomo tags" do
      get providers_path

      expect(meta_tags).to be_empty
    end

    it "gives a service page no event" do
      get service_path(create(:service))

      expect(events).to be_empty
    end

    it "gives a provider page no event" do
      get provider_path(create(:provider))

      expect(events).to be_empty
    end

    it "gives a bundle page no event" do
      bundle = create(:bundle)

      get service_bundle_path(bundle.service, bundle.iid)

      expect(events).to be_empty
    end

    context "with an offer added to a project" do
      include_context "with an offer added to a project"

      it "leaves only the notice in the flash" do
        expect(flash.to_hash).to eq("notice" => "Offer ordered successfully")
      end
    end

    context "with a rated project item" do
      include_context "with a rated project item"

      it "leaves only the notice in the flash" do
        expect(flash.to_hash).to eq("notice" => "Rating submitted successfully")
      end
    end
  end
end
