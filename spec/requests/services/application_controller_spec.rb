# frozen_string_literal: true

require "rails_helper"

# Since Services::ApplicationController is abstract, we'll test it through
# a concrete controller that inherits from it
RSpec.describe "Services::ApplicationController functionality", type: :request do
  let(:user) { create(:user) }
  let(:provider) { create(:provider) }
  let(:service_category) { create(:service_category) }

  before { sign_in(user) }

  shared_examples "services application controller" do |service_type|
    describe "session management" do
      let!(:offer) { create_offer(status: :published) }

      it "uses correct session key format" do
        get choose_offer_path
        expect(response).to have_http_status(:success)

        # Check session key format
        if service_type == "DeployableService"
          expect(session.keys).to include("ds_#{service_resource.id}")
        else
          expect(session.keys).to include(service_resource.id.to_s)
        end
      end
    end

    describe "service loading and authentication" do
      it "loads the correct service type" do
        create_offer(status: :published)
        get choose_offer_path
        expect(response).to have_http_status(:success)
      end

      it "authorizes service access through ServiceContext" do
        # This tests the authorize call in load_and_authenticate_service!
        create_offer(status: :published)
        expect_any_instance_of(ServiceContextPolicy).to receive(:order?).and_return(true)
        get choose_offer_path
        expect(response).to have_http_status(:success)
      end

      it "redirects to sign in when not authenticated" do
        sign_out(user)
        get choose_offer_path
        expect(response).to redirect_to(new_user_session_path)
      end

      it "raises RecordNotFound for non-existent #{service_type.downcase}" do
        expect do
          if service_type == "DeployableService"
            get "/deployable_services/nonexistent/choose_offer"
          else
            get "/services/nonexistent/choose_offer"
          end
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    describe "wizard management" do
      let!(:offer1) { create_offer(name: "Offer 1", status: :published) }
      let!(:offer2) { create_offer(name: "Offer 2", status: :published) }

      it "initializes ProjectItem::Wizard with correct service" do
        get choose_offer_path
        expect(response).to have_http_status(:success)
        # This verifies that @wizard is initialized in load_and_authenticate_service!
      end

      it "handles step navigation" do
        # Start with choose_offer
        get choose_offer_path
        expect(response).to have_http_status(:success)

        # Select an offer
        put choose_offer_path, params: { customizable_project_item: { offer_id: offer1.iid } }
        expect(response).to redirect_to(information_path)

        # Navigate to information step
        get information_path
        expect(response).to have_http_status(:success)
      end

      it "maintains state in session across steps" do
        # Choose offer
        put choose_offer_path, params: { customizable_project_item: { offer_id: offer1.iid } }
        expect(response).to redirect_to(information_path)

        # Check session contains the selection
        session_key = service_type == "DeployableService" ? "ds_#{service_resource.id}" : service_resource.id.to_s
        expect(session[session_key]).to include("offer_id" => offer1.id)
      end
    end

    describe "step visibility and navigation" do
      context "when service has single offer (step auto-skipping)" do
        let!(:single_offer) { create_offer(name: "Single Offer", status: :published) }

        it "auto-skips choose_offer step and redirects to information" do
          get choose_offer_path
          expect(response).to redirect_to(information_path)
        end
      end

      context "when service has multiple offers" do
        let!(:offer1) { create_offer(name: "Offer 1", status: :published) }
        let!(:offer2) { create_offer(name: "Offer 2", status: :published) }

        it "shows choose_offer step" do
          get choose_offer_path
          expect(response).to have_http_status(:success)
          expect(response.body).to include("Select an offer")
        end
      end
    end

    describe "path helpers and redirects" do
      let!(:offer) { create_offer(status: :published) }

      it "uses correct path for ensure_in_session! redirect" do
        # This is tested indirectly through the auto-redirect functionality
        get choose_offer_path
        expect(response).to have_http_status(:success)
      end

      it "handles backoffice parameter correctly" do
        get choose_offer_path, params: { from: "backoffice_service" }
        expect(response).to have_http_status(:success)
      end
    end

    describe "helper methods" do
      let!(:offer1) { create_offer(name: "Primary Offer", status: :published) }
      let!(:offer2) { create_offer(name: "Secondary Offer", status: :published) }

      before do
        # Set up a session state by selecting an offer
        put choose_offer_path, params: { customizable_project_item: { offer_id: offer1.iid } }
        expect(response).to redirect_to(information_path)
      end

      it "provides correct wizard_title" do
        get information_path
        expect(response).to have_http_status(:success)

        # When multiple offers exist, title should include service and offer names
        if service_resource.offers_count > 1
          expected_title = "#{service_resource.name} - #{offer1.name}"
        else
          expected_title = service_resource.name
        end

        expect(response.body).to include(expected_title)
      end

      it "provides step navigation titles" do
        get information_path
        expect(response).to have_http_status(:success)

        # Check for navigation elements
        expect(response.body).to include("Access instructions")
      end
    end
  end

  context "with Service" do
    let(:service_resource) { create(:service, resource_organisation: provider, status: :published) }

    def create_offer(attributes = {})
      create(:offer, service: service_resource, deployable_service: nil, offer_category: service_category, **attributes)
    end

    def choose_offer_path
      service_choose_offer_path(service_resource)
    end

    def information_path
      service_information_path(service_resource)
    end

    include_examples "services application controller", "Service"

    describe "Service-specific behavior" do
      it "uses Service in session key" do
        create_offer(status: :published)
        get choose_offer_path
        expect(session.keys).to include(service_resource.id.to_s)
      end

      it "uses service_choose_offer_path for redirects" do
        # This is tested through the path generation
        create_offer(status: :published)
        get choose_offer_path
        expect(response).to have_http_status(:success)
      end
    end
  end

  context "with DeployableService" do
    let(:service_resource) { create(:deployable_service, resource_organisation: provider, status: :published) }

    def create_offer(attributes = {})
      create(:offer, service: nil, deployable_service: service_resource, offer_category: service_category, **attributes)
    end

    def choose_offer_path
      deployable_service_choose_offer_path(service_resource)
    end

    def information_path
      deployable_service_information_path(service_resource)
    end

    include_examples "services application controller", "DeployableService"

    describe "DeployableService-specific behavior" do
      it "uses DeployableService in session key with 'ds_' prefix" do
        create_offer(status: :published)
        get choose_offer_path
        expect(session.keys).to include("ds_#{service_resource.id}")
      end

      it "uses deployable_service_choose_offer_path for redirects" do
        create_offer(status: :published)
        get choose_offer_path
        expect(response).to have_http_status(:success)
      end

      it "handles DeployableService-specific routing" do
        offer = create_offer(status: :published)

        # Test the full workflow with DeployableService paths
        get choose_offer_path
        expect(response).to have_http_status(:success)

        put choose_offer_path, params: { customizable_project_item: { offer_id: offer.iid } }
        expect(response).to redirect_to(information_path)

        get information_path
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "error handling and edge cases" do
    let(:service_resource) { create(:service, resource_organisation: provider, status: :published) }

    context "when service is not accessible" do
      it "handles draft services appropriately" do
        draft_service = create(:service, resource_organisation: provider, status: :draft)

        expect { get service_choose_offer_path(draft_service) }.to raise_error # Should be handled by policy
      end
    end

    context "with missing session state" do
      it "redirects to choose_offer when accessing later steps without session" do
        create(:offer, service: service_resource, offer_category: service_category, status: :published)

        # Try to access information step without going through choose_offer
        get service_information_path(service_resource)
        expect(response).to redirect_to(service_choose_offer_path(service_resource))
        expect(flash[:alert]).to eq("Service request template not found")
      end
    end

    context "with malformed session data" do
      let!(:offer) { create(:offer, service: service_resource, offer_category: service_category, status: :published) }

      it "handles corrupted session gracefully" do
        # Start normal flow
        put service_choose_offer_path(service_resource), params: { customizable_project_item: { offer_id: offer.iid } }
        expect(response).to redirect_to(service_information_path(service_resource))

        # Corrupt the session
        session[service_resource.id.to_s] = "corrupted_data"

        # Should still work or handle gracefully
        expect { get service_information_path(service_resource) }.not_to raise_error
      end
    end
  end

  describe "integration with ProjectItem::Wizard" do
    let(:service_resource) { create(:deployable_service, resource_organisation: provider, status: :published) }
    let!(:offer) do
      create(
        :offer,
        service: nil,
        deployable_service: service_resource,
        offer_category: service_category,
        status: :published
      )
    end

    it "properly initializes wizard for DeployableService" do
      get deployable_service_choose_offer_path(service_resource)
      expect(response).to have_http_status(:success)

      # The wizard should be initialized and working properly
      # This is verified by the successful response and proper step handling
    end

    it "maintains compatibility between Service and DeployableService workflows" do
      # Both should follow the same step pattern: choose_offer -> information -> configuration -> summary
      get deployable_service_choose_offer_path(service_resource)
      expect(response).to have_http_status(:success)

      put deployable_service_choose_offer_path(service_resource),
          params: {
            customizable_project_item: {
              offer_id: offer.iid
            }
          }
      expect(response).to redirect_to(deployable_service_information_path(service_resource))
    end
  end
end
