# frozen_string_literal: true

require "rails_helper"

RSpec.describe Backoffice::ServicePolicy, backend: true do
  let(:service_portfolio_manager) { create(:user, roles: [:service_portfolio_manager]) }
  let(:service_owner) do
    create(:user).tap do |user|
      service = create(:service)
      ServiceUserRelationship.create!(user: user, service: service)
    end
  end

  subject { described_class }

  context "permitted_attributes" do
    it "should return attrs if service has no upstream or is not persisted" do
      policy = described_class.new(service_owner, create(:service))
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
          # Research Product Policies
          [research_product_access_policy_ids: []],
          # Reseach Product Metadata
          [research_product_metadata_access_policy_ids: []],
          [research_step_ids: []],
          [entity_type_scheme_ids: []],
          [persistent_identity_systems_attributes: %i[id entity_type_id entity_type_scheme_ids _destroy]],
          [link_research_product_license_urls_attributes: %i[id url name _destroy]],
          [link_research_product_metadata_license_urls_attributes: %i[id url name _destroy]],
          [owner_ids: []],
          :status,
          :upstream_id,
          :version,
          :resource_organisation_id,
          [main_contact_attributes: %i[id first_name last_name email phone organisation position]],
          [sources_attributes: %i[id source_type eid _destroy]],
          [public_contacts_attributes: %i[id first_name last_name email phone organisation position _destroy]],
          [link_multimedia_urls_attributes: %i[id name url _destroy]],
          [link_use_cases_urls_attributes: %i[id name url _destroy]]
        ]
      )
    end

    it "should filter EOSC Registry managed fields if upstream is set to eosc_registry source" do
      service = create(:service)
      source = create(:service_source, source_type: :eosc_registry, service: service)
      service.update!(upstream: source)
      policy = described_class.new(service_owner, service)
      expect(policy.permitted_attributes).to match_array(
        [
          :restrictions,
          :activate_message,
          [owner_ids: []],
          :status,
          :upstream_id,
          :horizontal,
          [research_step_ids: []],
          [sources_attributes: %i[id source_type eid _destroy]]
        ]
      )
    end
  end

  context "service draft" do
    permissions :index? do
      it "grants access for service portfolio manager" do
        expect(subject).to permit(service_portfolio_manager, build(:service, status: :draft))
      end

      it "grants access for service owner" do
        expect(subject).to permit(service_owner, build(:service, status: :draft))
      end
    end

    permissions :show? do
      it "grants access for service portfolio manager" do
        expect(subject).to permit(service_portfolio_manager, build(:service, status: :draft))
      end

      it "grants access for owned service" do
        expect(subject).to permit(service_owner, service_owner.owned_services.first)
      end

      it "denies access for not owned service" do
        expect(subject).to_not permit(service_owner, build(:service, status: :draft))
      end
    end

    permissions :new?, :create?, :update? do
      it "grants access for service portfolio manager" do
        expect(subject).to permit(service_portfolio_manager, build(:service, status: :draft))
      end

      it "denies access for service owner" do
        expect(subject).to_not permit(service_owner, build(:service, status: :draft))
      end

      it "grants access for service portfolio manager" do
        expect(subject).to permit(service_portfolio_manager, build(:service, status: :draft))
      end
    end

    permissions :update? do
      let(:owner) { create(:user) }

      it "grants access for service owner when service is a draft" do
        service = create(:service, owners: [owner], status: :draft)

        expect(subject).to permit(owner, service)
      end

      it "allows access for service owner when service is published" do
        service = create(:service, owners: [owner], status: :published)

        expect(subject).to permit(owner, service)
      end
    end

    permissions :destroy? do
      it "grants access for service portfolio manager" do
        expect(subject).to permit(service_portfolio_manager, build(:service, status: :draft))
      end

      it "denies access for service owner" do
        expect(subject).to_not permit(service_owner, build(:service, status: :draft))
      end

      it "denies when service has project_items attached" do
        service = create(:service, status: :draft)
        create(:project_item, offer: create(:offer, service: service))

        expect(subject).to_not permit(service_portfolio_manager, service)
      end
    end
  end

  context "Service published" do
    permissions :index? do
      it "grants access for service portfolio manager" do
        expect(subject).to permit(service_portfolio_manager, build(:service))
      end

      it "grants access for service owner" do
        expect(subject).to permit(service_owner, build(:service))
      end
    end

    permissions :show? do
      it "grants access for service portfolio manager" do
        expect(subject).to permit(service_portfolio_manager, build(:service))
      end

      it "grants access for owned service" do
        expect(subject).to permit(service_owner, service_owner.owned_services.first)
      end

      it "denies access for not owned service" do
        expect(subject).to_not permit(service_owner, build(:service))
      end
    end

    permissions :update? do
      it "denies access for service portfolio manager" do
        expect(subject).to permit(service_portfolio_manager, build(:service))
      end

      it "denies access for service owner" do
        expect(subject).to_not permit(service_owner, build(:service))
      end
    end

    permissions :destroy? do
      it "denies access for service portfolio manager" do
        expect(subject).to_not permit(service_portfolio_manager, build(:service))
      end

      it "denies access for service owner" do
        expect(subject).to_not permit(service_owner, build(:service))
      end

      it "denies when service has project_items attached" do
        service = create(:service)
        create(:project_item, offer: create(:offer, service: service))

        expect(subject).to_not permit(service_portfolio_manager, service)
      end
    end
  end

  context "#scope" do
    it "returns all services for service portfolio manager" do
      create_list(:service, 2)

      scope = described_class::Scope.new(service_portfolio_manager, Service.all)

      expect(scope.resolve.count).to eq(2)
    end

    it "returns only owned services for service owner" do
      _not_owned = create(:service)

      scope = described_class::Scope.new(service_owner, Service.all)

      expect(scope.resolve).to contain_exactly(*service_owner.owned_services)
    end

    it "returns nothing for normal user" do
      create(:service)

      scope = described_class::Scope.new(create(:user), Service.all)

      expect(scope.resolve.count).to be_zero
    end
  end

  permissions :publish? do
    it "grants access for service portfolio manager and not published services" do
      expect(subject).to permit(service_portfolio_manager, build(:service, status: :draft))
      expect(subject).to permit(service_portfolio_manager, build(:service, status: :unverified))
    end

    it "denies access for other users" do
      expect(subject).to_not permit(service_owner, build(:service, status: :draft))
    end

    it "denies access for already published service" do
      expect(subject).to_not permit(service_portfolio_manager, build(:service, status: :published))
    end
  end

  permissions :publish_unverified? do
    it "grants access for service portfolio manager and not published unverified services" do
      expect(subject).to permit(service_portfolio_manager, build(:service, status: :draft))
      expect(subject).to permit(service_portfolio_manager, build(:service, status: :published))
    end

    it "denies access for other users" do
      expect(subject).to_not permit(service_owner, build(:service, status: :draft))
    end

    it "denies access for already published unverified service" do
      expect(subject).to_not permit(service_portfolio_manager, build(:service, status: :unverified))
    end
  end

  permissions :draft? do
    it "grants access for service portfolio manager and not draft services" do
      expect(subject).to permit(service_portfolio_manager, build(:service, status: :published))
      expect(subject).to permit(service_portfolio_manager, build(:service, status: :unverified))
    end

    it "denies access for other users" do
      expect(subject).to_not permit(service_owner, build(:service, status: :published))
    end

    it "denies access fo service in draft state" do
      expect(subject).to_not permit(service_portfolio_manager, build(:service, status: :draft))
    end
  end

  context "When offer is draft and service is deleted" do
    let(:service) { create(:service, owners: [service_owner], status: :deleted) }

    permissions :edit?, :update?, :destroy?, :publish?, :draft?, :publish_unverified? do
      it "danies access to service portfolio manager" do
        expect(subject).to_not permit(service_portfolio_manager, service)
      end

      it "danies access to service owner" do
        expect(subject).to_not permit(service_owner, service)
      end
    end
  end
end
