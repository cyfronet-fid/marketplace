# frozen_string_literal: true

require "rails_helper"

RSpec.describe Backoffice::ServicePolicy, :backend do
  subject { described_class }

  let(:coordinator) { create(:user, roles: [:coordinator]) }
  let!(:provider_data_administrator) { create(:user) }
  let!(:provider) do
    create(:provider, data_administrators: [build(:data_administrator, email: provider_data_administrator&.email)])
  end
  let!(:catalogue_data_administrator) { create(:user) }
  let!(:catalogue) do
    create(:catalogue, data_administrators: [build(:data_administrator, email: catalogue_data_administrator&.email)])
  end

  let(:basic_user) { create(:user) }

  context "permitted_attributes" do
    it "returns attrs if service has no upstream or is not persisted" do
      policy = described_class.new(coordinator, create(:service))
      attrs = policy.permitted_attributes

      expect(attrs).to include(
        :name,
        :publishing_date,
        :resource_type,
        [urls: []],
        [public_contact_emails: []],
        :jurisdiction_id,
        [research_product_types: []],
        [sources_attributes: %i[id source_type eid _destroy]]
      )
      expect(attrs).not_to include(
        :abbreviation,
        :tagline,
        :activate_message,
        :submission_policy_url,
        :preservation_policy_url,
        :harvestable,
        [platform_ids: []],
        [target_user_ids: []],
        [marketplace_location_ids: []],
        [research_entity_type_ids: []],
        [research_product_access_policy_ids: []],
        [research_product_metadata_access_policy_ids: []]
      )
    end

    it "filters EOSC Registry managed fields if upstream is set to eosc_registry source" do
      service = create(:service)
      source = create(:service_source, source_type: :eosc_registry, service: service)
      service.update!(upstream: source)
      policy = described_class.new(coordinator, service)
      expect(policy.permitted_attributes).to contain_exactly(:type, :status, :upstream_id, [owner_ids: []],
                                                             [sources_attributes: %i[id source_type eid _destroy]])
    end
  end

  context "service draft" do
    let(:service_owner) do
      create(:user).tap do |user|
        ServiceUserRelationship.create!(user: user, service: create(:service))
        user.reload
      end
    end

    permissions :index? do
      it "grants access for service portfolio manager" do
        expect(subject).to permit(coordinator, build(:service, status: :draft))
      end

      it "grants access for service owner" do
        expect(subject).to permit(service_owner, build(:service, status: :draft))
      end

      it "grants access for provider data administrator" do
        provider_data_administrator.reload
        expect(subject).to permit(
          provider_data_administrator,
          build(:service, resource_organisation: provider, status: :draft)
        )
      end

      it "grants access for catalogue data administrator" do
        catalogue_data_administrator.reload
        expect(subject).to permit(catalogue_data_administrator, build(:service, catalogue: catalogue, status: :draft))
      end

      it "denies access for basic user" do
        expect(subject).not_to permit(basic_user, build(:service, status: :draft))
      end
    end

    permissions :show? do
      it "grants access for service portfolio manager" do
        expect(subject).to permit(coordinator, build(:service, status: :draft))
      end

      it "grants access for provider data administrator" do
        expect(subject).to permit(provider_data_administrator, build(:service, resource_organisation: provider))
      end

      it "denies access for provider data administrator of other service" do
        expect(subject).not_to permit(provider_data_administrator, build(:service, status: :draft))
      end

      it "grants access for catalogue data administrator" do
        expect(subject).to permit(catalogue_data_administrator, build(:service, catalogue: catalogue))
      end

      it "denies access for not owned service" do
        expect(subject).not_to permit(basic_user, build(:service, status: :draft))
      end
    end

    permissions :new?, :create?, :update? do
      it "grants access for service portfolio manager" do
        expect(subject).to permit(coordinator, build(:service, status: :draft))
      end

      it "grants access for provider data administrator" do
        provider_data_administrator.reload
        expect(subject).to permit(provider_data_administrator, build(:service, resource_organisation: provider))
      end

      it "grants access for catalogue data administrator" do
        catalogue_data_administrator.reload
        expect(subject).to permit(catalogue_data_administrator, build(:service, catalogue: catalogue))
      end

      it "grants access for service portfolio manager" do
        expect(subject).to permit(coordinator, build(:service, status: :draft))
      end
    end

    permissions :destroy? do
      it "grants access for service portfolio manager" do
        expect(subject).to permit(coordinator, build(:service, status: :draft))
      end

      it "allows when service has project_items attached" do
        service = create(:service, status: :draft)
        create(:project_item, offer: create(:offer, service: service))

        expect(subject).to permit(coordinator, service)
      end
    end
  end

  context "Service published" do
    permissions :index? do
      it "grants access for service portfolio manager" do
        expect(subject).to permit(coordinator, build(:service))
      end
    end

    permissions :show? do
      it "grants access for service portfolio manager" do
        expect(subject).to permit(coordinator, build(:service))
      end

      it "denies access for not owned service" do
        expect(subject).not_to permit(basic_user, build(:service))
      end
    end

    permissions :update? do
      it "denies access for service portfolio manager" do
        expect(subject).to permit(coordinator, build(:service))
      end

      it "denies access for service owner" do
        expect(subject).not_to permit(basic_user, build(:service))
      end
    end

    permissions :destroy? do
      it "allows access for service portfolio manager" do
        expect(subject).to permit(coordinator, build(:service))
      end

      it "denies access for user" do
        expect(subject).not_to permit(basic_user, build(:service))
      end

      it "allows when service has project_items attached" do
        service = create(:service)
        create(:project_item, offer: create(:offer, service: service))

        expect(subject).to permit(coordinator, service)
      end
    end
  end

  describe "#scope" do
    it "returns all services for service portfolio manager" do
      create_list(:service, 2)

      scope = described_class::Scope.new(coordinator, Service.all)

      expect(scope.resolve.count).to eq(2)
    end

    it "returns nothing for normal user" do
      create(:service)

      scope = described_class::Scope.new(create(:user), Service.all)

      expect(scope.resolve.count).to be_zero
    end
  end

  permissions :publish? do
    it "grants access for service portfolio manager and not published services" do
      expect(subject).to permit(coordinator, build(:service, status: :draft))
      expect(subject).to permit(coordinator, build(:service, status: :suspended))
    end

    it "denies access for other users" do
      expect(subject).not_to permit(basic_user, build(:service, status: :draft))
    end

    it "denies access for already published service" do
      expect(subject).not_to permit(coordinator, build(:service, status: :published))
    end
  end

  permissions :unpublish? do
    it "grants access for service portfolio manager and not draft services" do
      expect(subject).to permit(coordinator, build(:service, status: :published))
      expect(subject).to permit(coordinator, build(:service, status: :errored))
    end

    it "denies access for other users" do
      expect(subject).not_to permit(basic_user, build(:service, status: :published))
    end

    it "denies access fo service in unpublished state" do
      expect(subject).not_to permit(coordinator, build(:service, status: :unpublished))
    end
  end

  context "when the service is deleted" do
    permissions :show? do
      it "denies access for service portfolio manager" do
        expect(subject).not_to permit(coordinator, build(:service, status: :deleted))
      end
    end

    permissions :edit?, :update?, :destroy? do
      it "grants access for service portfolio manager" do
        expect(subject).to permit(coordinator, build(:service, status: :deleted))
      end
    end
  end

  permissions :create? do
    it "denies access for data administrator of another organisation" do
      provider_data_administrator.reload
      expect(subject).not_to permit(provider_data_administrator, build(:service))
    end
  end

  context "when running as pl or whitelabel" do
    before { allow(Mp::Variant).to receive(:marketplace?).and_return(false) }

    permissions :show? do
      it "grants access for service portfolio manager to a deleted service" do
        expect(subject).to permit(coordinator, build(:service, status: :deleted))
      end
    end

    permissions :edit?, :update?, :destroy? do
      it "denies access for service portfolio manager to a deleted service" do
        expect(subject).not_to permit(coordinator, build(:service, status: :deleted))
      end
    end

    permissions :create? do
      it "grants access for data administrator of another organisation" do
        provider_data_administrator.reload
        expect(subject).to permit(provider_data_administrator, build(:service))
      end

      it "denies access for basic user" do
        expect(subject).not_to permit(basic_user, build(:service))
      end
    end

    it "does not lock registry-imported services to internal fields" do
      service = create(:service)
      source = create(:service_source, source_type: :eosc_registry, service: service)
      service.update!(upstream: source)
      policy = described_class.new(coordinator, service)

      expect(policy.permitted_attributes).to include(:name)
    end
  end

  context "when running as pl" do
    subject(:attrs) { described_class.new(coordinator, build(:service)).permitted_attributes }

    before { allow(Mp::Variant).to receive(:pl?).and_return(true) }

    it "permits the PL profile and V5 fields" do
      expect(attrs).to include(:tagline, :abbreviation, :harvestable, [platform_ids: []], [target_user_ids: []])
    end
  end

  context "when running as whitelabel" do
    subject(:attrs) { described_class.new(coordinator, build(:service)).permitted_attributes }

    before { allow(Mp::Variant).to receive_messages(marketplace?: false, pl?: false, whitelabel?: true) }

    it "permits the shared fields" do
      expect(attrs).to include(:name)
    end

    it "does not permit service owners" do
      expect(attrs).not_to include([owner_ids: []])
    end
  end
end
