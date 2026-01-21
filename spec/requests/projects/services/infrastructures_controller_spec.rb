# frozen_string_literal: true

require "rails_helper"

RSpec.describe Projects::Services::InfrastructuresController, type: :request do
  let(:user) { create(:user) }
  let(:project) { create(:project, user: user) }
  let(:provider) { create(:provider) }
  let(:deployable_service) { create(:deployable_service, resource_organisation: provider) }
  let(:service_category) { create(:service_category) }
  let(:offer) { create(:offer, service: nil, deployable_service: deployable_service, offer_category: service_category) }
  let(:project_item) { create(:project_item, offer: offer, project: project) }

  describe "DELETE /projects/:project_id/services/:service_id/infrastructure" do
    context "when user is not logged in" do
      it "redirects to login" do
        delete project_service_infrastructure_path(project, project_item)
        expect(response).to have_http_status(:redirect)
      end
    end

    context "when user is logged in" do
      before { login_as(user) }

      context "with destroyable infrastructure" do
        let!(:infrastructure) do
          Infrastructure.create!(
            project_item: project_item,
            im_base_url: "https://example.com",
            cloud_site: "test",
            state: "running",
            im_infrastructure_id: "infra-123"
          )
        end

        it "enqueues the destroy job" do
          expect { delete project_service_infrastructure_path(project, project_item) }.to have_enqueued_job(
            Infrastructure::DestroyJob
          ).with(infrastructure.id)
        end

        it "redirects to project service page" do
          delete project_service_infrastructure_path(project, project_item)
          expect(response).to redirect_to(project_service_path(project, project_item))
        end

        it "sets a success flash message" do
          delete project_service_infrastructure_path(project, project_item)
          expect(flash[:notice]).to include("destruction has been initiated")
        end
      end

      context "without infrastructure" do
        it "redirects to root with alert (not authorized)" do
          delete project_service_infrastructure_path(project, project_item)
          expect(response).to redirect_to(root_path(anchor: ""))
          expect(flash[:alert]).to be_present
        end

        it "does not enqueue any job" do
          expect { delete project_service_infrastructure_path(project, project_item) }.not_to have_enqueued_job(
            Infrastructure::DestroyJob
          )
        end
      end

      context "with non-destroyable infrastructure" do
        let!(:infrastructure) do
          Infrastructure.create!(
            project_item: project_item,
            im_base_url: "https://example.com",
            cloud_site: "test",
            state: "pending"
          )
        end

        it "redirects to root with alert (not authorized)" do
          delete project_service_infrastructure_path(project, project_item)
          expect(response).to redirect_to(root_path(anchor: ""))
          expect(flash[:alert]).to be_present
        end
      end
    end

    context "when user is not the project owner" do
      let(:other_user) { create(:user) }

      before { login_as(other_user) }

      let!(:infrastructure) do
        Infrastructure.create!(
          project_item: project_item,
          im_base_url: "https://example.com",
          cloud_site: "test",
          state: "running",
          im_infrastructure_id: "infra-123"
        )
      end

      it "redirects to root with alert (not authorized)" do
        delete project_service_infrastructure_path(project, project_item)
        expect(response).to redirect_to(root_path(anchor: ""))
        expect(flash[:alert]).to be_present
      end
    end
  end
end
