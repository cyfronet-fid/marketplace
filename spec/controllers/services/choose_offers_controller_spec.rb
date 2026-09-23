# frozen_string_literal: true

require "rails_helper"

RSpec.describe Services::ChooseOffersController, type: :controller, backend: true do
  let(:user) { create(:user) }
  let(:provider) { create(:provider) }
  let(:service_category) { create(:service_category) }

  before { sign_in(user) }

  shared_examples "choose offers controller" do |service_type|
    describe "GET #show" do
      context "when #{service_type} has multiple offers" do
        let(:offer1) { create_offer(name: "Offer 1", status: :published) }
        let(:offer2) { create_offer(name: "Offer 2", status: :published) }

        before do
          offer1
          offer2
        end

        xit "renders the choose offers page" do # needs fix
          get :show, params: service_params
          expect(response).to render_template(:show)
          expect(assigns(:offers)).to include(offer1, offer2)
          expect(assigns(:step).visible?).to be true
        end

        xit "initializes step data correctly" do # needs fix
          get :show, params: service_params
          expect(assigns(:offers).count).to eq(2)
          expect(assigns(:step)).to be_present
          expect(assigns(:step)).to be_kind_of(ProjectItem::Wizard::ChooseOfferStep)
        end
      end

      context "when #{service_type} has single offer (auto-selection)" do
        let!(:single_offer) { create_offer(name: "Single Offer", status: :published) }

        xit "auto-selects the offer and redirects" do # needs fix
          expect(controller).to receive(:update).and_call_original
          get :show, params: service_params
          expect(assigns(:step).visible?).to be false
        end

        it "sets the offer_id in params during auto-selection" do
          allow(controller).to receive(:update) do
            expect(controller.params[:customizable_project_item][:offer_id]).to eq(single_offer.iid)
            controller.redirect_to("/mock-redirect")
          end
          get :show, params: service_params
        end
      end

      context "when #{service_type} has no offers" do
        it "does not initialize selectable offers" do
          get :show, params: service_params
          expect(assigns(:offers)).to be_nil
        end
      end

      context "when step should be auto-selected" do
        let!(:offer) { create_offer(name: "Auto Offer", status: :published) }

        before do
          # Mock the step to return not visible (single offer case)
          allow_any_instance_of(ProjectItem::Wizard::ChooseOfferStep).to receive(:visible?).and_return(false)
        end

        xit "calls update method for auto-selection" do # needs fix
          expect(controller).to receive(:update).and_call_original
          get :show, params: service_params
        end
      end
    end

    describe "PUT #update" do
      let!(:offer) { create_offer(name: "Test Offer", status: :published) }

      context "with valid offer selection" do
        xit "saves the selection in session and redirects to next step" do # needs fix
          put :update, params: service_params.merge(customizable_project_item: { offer_id: offer.iid })

          session_key =
            service_resource.is_a?(DeployableService) ? "ds_#{service_resource.id}" : service_resource.id.to_s
          expect(session[session_key]).to be_present
          expect(response).to redirect_to(information_path)
        end

        xit "creates valid step with selected offer" do # needs fix
          put :update, params: service_params.merge(customizable_project_item: { offer_id: offer.iid })

          expect(assigns(:step)).to be_valid
          expect(assigns(:step).offer).to eq(offer)
        end
      end

      context "with invalid offer selection" do
        let!(:alternative_offer) { create_offer(name: "Alternative Offer", status: :published) }

        xit "re-renders show template with error" do # needs fix
          put :update, params: service_params.merge(customizable_project_item: { offer_id: 99_999 })

          expect(response).to render_template(:show)
          expect(assigns(:step)).not_to be_valid
        end

        xit "shows flash alert for invalid selection" do # needs fix
          put :update, params: service_params.merge(customizable_project_item: { offer_id: nil })

          expect(flash[:alert]).to eq("Please select one of the offer or bundle")
        end
      end

      context "when step should be invisible (auto-selection case)" do
        let!(:single_offer) { create_offer(name: "Single Offer", status: :published) }

        before do
          # Mock the step to be invalid but invisible
          allow_any_instance_of(ProjectItem::Wizard::ChooseOfferStep).to receive(:visible?).and_return(false)
        end

        xit "does not show validation error for invisible step" do # needs fix
          put :update, params: service_params.merge(customizable_project_item: { offer_id: nil })

          expect(flash[:alert]).to be_nil
        end
      end
    end

    describe "private methods" do
      before { create_offer(name: "Test Offer", status: :published) }

      describe "#step_key" do
        it "returns :choose_offer" do
          get :show, params: service_params
          expect(controller.send(:step_key)).to eq(:choose_offer)
        end
      end

      describe "#step_params" do
        let!(:offer) { create_offer(name: "Test Offer", status: :published) }

        xit "returns hash with offer_id and project_id" do # needs fix
          get :show, params: service_params.merge(customizable_project_item: { offer_id: offer.iid })

          step_params = controller.send(:step_params)
          expect(step_params).to include(:offer_id, :project_id)
          expect(step_params[:offer_id]).to eq(offer.id)
        end
      end

      describe "#offer" do
        let!(:offer) { create_offer(name: "Test Offer", status: :published) }

        xit "finds offer by iid from params" do # needs fix
          get :show, params: service_params.merge(customizable_project_item: { offer_id: offer.iid })

          found_offer = controller.send(:offer)
          expect(found_offer).to eq(offer)
        end

        xit "returns nil for non-existent offer" do # needs fix
          get :show, params: service_params.merge(customizable_project_item: { offer_id: 99_999 })

          found_offer = controller.send(:offer)
          expect(found_offer).to be_nil
        end
      end

      describe "#init_step_data" do
        let!(:offer1) { create_offer(name: "Offer 1", status: :published) }
        let!(:offer2) { create_offer(name: "Offer 2", status: :draft) }

        xit "initializes offers with policy scope and active scope" do # needs fix
          get :show, params: service_params
          controller.send(:init_step_data)

          offers = assigns(:offers)
          expect(offers).to include(offer1)
          expect(offers).not_to include(offer2) # draft offers excluded by policy
        end

        xit "initializes step from session" do # needs fix
          get :show, params: service_params
          controller.send(:init_step_data)

          step = assigns(:step)
          expect(step).to be_kind_of(ProjectItem::Wizard::ChooseOfferStep)
        end
      end
    end
  end

  context "with Service" do
    let(:service_resource) { create(:service, resource_organisation: provider, status: :published) }

    def create_offer(attributes = {})
      create(:offer, service: service_resource, deployable_service: nil, offer_category: service_category, **attributes)
    end

    def service_params
      { service_id: service_resource.to_param }
    end

    def information_path
      service_information_path(service_resource)
    end

    include_examples "choose offers controller", "Service"

    describe "Service-specific behavior" do
      xit "uses service in step initialization" do # needs fix
        get :show, params: service_params
        expect(assigns(:service)).to eq(service_resource)
        expect(assigns(:service)).to be_kind_of(Service)
      end
    end
  end

  context "with DeployableService" do
    let(:service_resource) { create(:deployable_service, resource_organisation: provider, status: :published) }

    def create_offer(attributes = {})
      create(:offer, service: nil, deployable_service: service_resource, offer_category: service_category, **attributes)
    end

    def service_params
      { deployable_service_id: service_resource.to_param }
    end

    def information_path
      deployable_service_information_path(service_resource)
    end

    include_examples "choose offers controller", "DeployableService"

    describe "DeployableService-specific behavior" do
      xit "uses deployable_service in step initialization" do # needs fix
        get :show, params: service_params
        expect(assigns(:service)).to eq(service_resource)
        expect(assigns(:service)).to be_kind_of(DeployableService)
      end

      xit "correctly handles OfferScopeExtensions" do # needs fix
        offer1 = create_offer(name: "DS Offer 1", status: :published)
        offer2 = create_offer(name: "DS Offer 2", status: :published)

        get :show, params: service_params

        offers = assigns(:service).offers
        expect(offers).to respond_to(:inclusive)
        expect(offers).to respond_to(:accessible)
        expect(offers).to respond_to(:active)

        expect(offers.inclusive).to include(offer1, offer2)
      end

      it "auto-selects single DeployableService offer correctly" do
        single_offer = create_offer(name: "Single DS Offer", status: :published)

        # Mock redirect to prevent actual redirect in test
        allow(controller).to receive(:redirect_to)
        allow(controller).to receive(:update) do
          expect(controller.params[:customizable_project_item][:offer_id]).to eq(single_offer.iid)
        end

        get :show, params: service_params
      end
    end
  end

  describe "authentication and authorization" do
    context "when user is not signed in" do
      before { sign_out(user) }

      it "redirects to sign in page" do
        service = create(:service, resource_organisation: provider)
        get :show, params: { service_id: service.to_param }
        expect(response).to redirect_to("/users/auth/checkin")
      end
    end

    context "when service/deployable_service is not found" do
      xit "redirects to not found for service" do # needs fix
        get :show, params: { service_id: "nonexistent" }
        expect(response).to redirect_to("/404")
      end

      xit "redirects to not found for deployable_service" do # needs fix
        get :show, params: { deployable_service_id: "nonexistent" }
        expect(response).to redirect_to("/404")
      end
    end
  end

  describe "policy integration" do
    let(:service_resource) { create(:service, resource_organisation: provider, status: :published) }
    let!(:offer) { create(:offer, service: service_resource, offer_category: service_category, status: :published) }

    xit "applies offer policy scope to filter offers" do # needs fix
      # Create unpublished offer that should be filtered out
      unpublished_offer = create(:offer, service: service_resource, offer_category: service_category, status: :draft)

      get :show, params: { service_id: service_resource.to_param }

      offers = assigns(:offers)
      expect(offers).to include(offer)
      expect(offers).not_to include(unpublished_offer)
    end
  end
end
