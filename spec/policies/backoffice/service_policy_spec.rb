# frozen_string_literal: true

require "rails_helper"

RSpec.describe Backoffice::ServicePolicy, backend: true do
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

  subject { described_class }

  context "permitted_attributes" do
    it "should return attrs if service has no upstream or is not persisted" do
      policy = described_class.new(coordinator, create(:service))
      expect(policy.permitted_attributes).to match_array(
        [
          :type,
          :name,
          :abbreviation,
          :description,
          :tagline,
          :order_type,
          [provider_ids: []],
          [geographical_availabilities: []],
          [language_availability: []],
          [resource_geographic_locations: []],
          [target_user_ids: []],
          :terms_of_use_url,
          :access_policies_url,
          :resource_level_url,
          :webpage_url,
          :manual_url,
          :helpdesk_url,
          :privacy_policy_url,
          [funding_body_ids: []],
          [funding_program_ids: []],
          [access_type_ids: []],
          [access_mode_ids: []],
          [certifications: []],
          [standards: []],
          [grant_project_names: []],
          [open_source_technologies: []],
          [changelog: []],
          :helpdesk_email,
          :security_contact_email,
          :training_information_url,
          :restrictions,
          :status_monitoring_url,
          :maintenance_url,
          :order_url,
          :payment_model_url,
          :pricing_url,
          [related_service_ids: []],
          [required_service_ids: []],
          [manual_related_service_ids: []],
          :catalogue,
          :catalogue_id,
          :activate_message,
          :logo,
          [trl_ids: []],
          [life_cycle_status_ids: []],
          [scientific_domain_ids: []],
          [platform_ids: []],
          [related_platforms: []],
          :tag_list,
          [category_ids: []],
          [pc_category_ids: []],
          :horizontal,
          # Datasource Policies
          :submission_policy_url,
          :preservation_policy_url,
          :version_control,
          # Datasource content
          :jurisdiction_id,
          :datasource_classification_id,
          [research_entity_type_ids: []],
          :thematic,
          :harvestable,
          # Research Product Policies
          [research_product_access_policy_ids: []],
          # Reseach Product Metadata
          [research_product_metadata_access_policy_ids: []],
          [service_category_ids: []],
          [research_activity_ids: []],
          [entity_type_scheme_ids: []],
          [persistent_identity_systems_attributes: %i[id entity_type_id entity_type_scheme_ids _destroy]],
          [link_research_product_license_urls_attributes: %i[id url name _destroy]],
          [link_research_product_metadata_license_urls_attributes: %i[id url name _destroy]],
          :status,
          :upstream_id,
          :version,
          :resource_organisation_id,
          [main_contact_attributes: %i[id first_name last_name email phone country_phone_code organisation position]],
          [sources_attributes: %i[id source_type eid _destroy]],
          [
            public_contacts_attributes: %i[
              id
              first_name
              last_name
              email
              phone
              country_phone_code
              organisation
              position
              _destroy
            ]
          ],
          [link_multimedia_urls_attributes: %i[id name url _destroy]],
          [link_use_cases_urls_attributes: %i[id name url _destroy]],
          [alternative_identifiers_attributes: %i[id identifier_type value _destroy]]
        ]
      )
    end

    it "should filter EOSC Registry managed fields if upstream is set to eosc_registry source",
       skip: "Not valid in the whitelabel use-case" do
      service = create(:service)
      source = create(:service_source, source_type: :eosc_registry, service: service)
      service.update!(upstream: source)
      policy = described_class.new(coordinator, service)
      expect(policy.permitted_attributes).to match_array(
        [
          :type,
          :restrictions,
          :activate_message,
          [owner_ids: []],
          :status,
          :upstream_id,
          :horizontal,
          [research_activity_ids: []],
          [sources_attributes: %i[id source_type eid _destroy]]
        ]
      )
    end
  end

  context "service draft" do
    permissions :index? do
      it "grants access for service portfolio manager" do
        expect(subject).to permit(coordinator, build(:service, status: :draft))
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
        expect(subject).to_not permit(basic_user, build(:service, status: :draft))
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
        expect(subject).to_not permit(provider_data_administrator, build(:service, status: :draft))
      end

      it "grants access for catalogue data administrator" do
        expect(subject).to permit(catalogue_data_administrator, build(:service, catalogue: catalogue))
      end

      it "denies access for not owned service" do
        expect(subject).to_not permit(basic_user, build(:service, status: :draft))
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
        expect(subject).to_not permit(basic_user, build(:service))
      end
    end

    permissions :update? do
      it "denies access for service portfolio manager" do
        expect(subject).to permit(coordinator, build(:service))
      end

      it "denies access for service owner" do
        expect(subject).to_not permit(basic_user, build(:service))
      end
    end

    permissions :destroy? do
      it "allows access for service portfolio manager" do
        expect(subject).to permit(coordinator, build(:service))
      end

      it "denies access for user" do
        expect(subject).to_not permit(basic_user, build(:service))
      end

      it "allows when service has project_items attached" do
        service = create(:service)
        create(:project_item, offer: create(:offer, service: service))

        expect(subject).to permit(coordinator, service)
      end
    end
  end

  context "#scope" do
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
      expect(subject).to_not permit(basic_user, build(:service, status: :draft))
    end

    it "denies access for already published service" do
      expect(subject).to_not permit(coordinator, build(:service, status: :published))
    end
  end

  permissions :unpublish? do
    it "grants access for service portfolio manager and not draft services" do
      expect(subject).to permit(coordinator, build(:service, status: :published))
      expect(subject).to permit(coordinator, build(:service, status: :errored))
    end

    it "denies access for other users" do
      expect(subject).to_not permit(basic_user, build(:service, status: :published))
    end

    it "denies access fo service in unpublished state" do
      expect(subject).to_not permit(coordinator, build(:service, status: :unpublished))
    end
  end
end
