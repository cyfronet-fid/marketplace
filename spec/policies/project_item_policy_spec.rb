# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectItemPolicy, backend: true do
  let(:user) { create(:user) }

  subject { described_class }

  permissions :index?, :new? do
    it "grants access for logged in user" do
      expect(subject).to permit(user)
    end
  end

  permissions :create? do
    it "grants access to create item in owned project" do
      expect(subject).to permit(user, build(:project_item, project: build(:project, user: user)))
    end
  end

  permissions :show? do
    it "grants access for project_item owner" do
      expect(subject).to permit(user, build(:project_item, project: build(:project, user: user)))
    end

    it "denies to see other user owners" do
      expect(subject).to_not permit(user, build(:project_item))
    end
  end

  permissions :destroy_infrastructure? do
    let(:provider) { create(:provider) }
    let(:deployable_service) { create(:deployable_service, resource_organisation: provider) }
    let(:service_category) { create(:service_category) }
    let(:offer) do
      create(:offer, service: nil, deployable_service: deployable_service, offer_category: service_category)
    end
    let(:project) { create(:project, user: user) }
    let(:project_item) { create(:project_item, offer: offer, project: project) }

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

      it "grants access to project owner" do
        expect(subject).to permit(user, project_item)
      end

      it "denies access to non-owner" do
        other_user = create(:user)
        expect(subject).not_to permit(other_user, project_item)
      end

      it "denies access to nil user" do
        expect(subject).not_to permit(nil, project_item)
      end
    end

    context "without infrastructure" do
      it "denies access even to project owner" do
        expect(subject).not_to permit(user, project_item)
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

      it "denies access when infrastructure cannot be destroyed" do
        expect(subject).not_to permit(user, project_item)
      end
    end

    context "with already destroyed infrastructure" do
      let!(:infrastructure) do
        infra =
          Infrastructure.create!(
            project_item: project_item,
            im_base_url: "https://example.com",
            cloud_site: "test",
            state: "running",
            im_infrastructure_id: "infra-123"
          )
        infra.update_columns(state: "destroyed")
        infra
      end

      it "denies access for destroyed infrastructure" do
        expect(subject).not_to permit(user, project_item)
      end
    end
  end
end
