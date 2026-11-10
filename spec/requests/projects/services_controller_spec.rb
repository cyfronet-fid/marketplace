# frozen_string_literal: true

require "rails_helper"

RSpec.describe Projects::ServicesController, type: :request do
  let(:project) { create(:project) }
  let(:deployable_service) { create(:deployable_service, resource_organisation: resource_organisation) }
  let(:offer) { create(:offer, deployable_service: deployable_service) }
  let(:project_item) { create(:project_item, offer: offer, project: project) }

  describe "GET /projects/:project_id/services/:id" do
    before do
      login_as(project.user)
      get project_service_path(project, project_item)
    end

    context "when the deployable service has a resource organisation" do
      let(:resource_organisation) { create(:provider) }

      it "shows the organisation section" do
        expect(response.body).to include(">Organisation<")
      end
    end

    # Importers::DeployableService leaves it nil when the resourceOwner is not a known provider
    context "when the deployable service has no resource organisation" do
      let(:resource_organisation) { nil }

      it "renders the page without the organisation section", :aggregate_failures do
        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include(">Organisation<")
      end
    end
  end
end
