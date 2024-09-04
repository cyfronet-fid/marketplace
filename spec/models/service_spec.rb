# frozen_string_literal: true

require "rails_helper"
require_relative "publishable"

RSpec.describe Service, backend: true do
  include_examples "publishable"

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:description) }
  it { should validate_presence_of(:tagline) }
  it { should validate_presence_of(:rating) }

  it { should have_many(:providers) }
  it { should have_many(:categorizations).dependent(:destroy) }
  it { should have_many(:offers).dependent(:restrict_with_error) }
  it { should have_many(:categories) }
  it { should have_many(:service_scientific_domains).dependent(:destroy) }
  it { should have_many(:funding_bodies) }
  it { should have_many(:funding_programs) }
  it { should have_many(:service_vocabularies).dependent(:destroy) }

  it { should belong_to(:upstream).required(false) }

  it "sets first category as default" do
    c1, c2 = create_list(:category, 2)
    service = create(:service, categories: [c1, c2])

    expect(service.categorizations.first.main).to be_truthy
    expect(service.categorizations.second.main).to be_falsy
  end

  it "allows to have only one main category" do
    c1, c2 = create_list(:category, 2)
    service = create(:service, categories: [c1])

    service.categorizations.create(category: c2, main: true)
    old_main = service.categorizations.find_by(category: c1)

    expect(old_main.main).to be_falsy
  end

  it "has main category" do
    main, other = create_list(:category, 2)
    service = create(:service, categories: [main, other])

    expect(service.main_category).to eq(main)
  end

  it "has rating" do
    expect(create(:service).rating).to eq(0.0)
  end

  it "has related services" do
    s1, s2, s3 = create_list(:service, 3)

    ServiceRelationship.create!(source: s1, target: s2, type: "ServiceRelationship")
    ServiceRelationship.create!(source: s1, target: s3, type: "ServiceRelationship")

    expect(s1.related_services).to contain_exactly(s2, s3)
  end

  context "#owned_by?" do
    it "is true when user is in the data administrator of provider" do
      owner = create(:user)
      provider = create(:provider, data_administrators: [build(:data_administrator, email: owner.email)])
      service = create(:service, resource_organisation: provider)

      expect(service.owned_by?(owner)).to be_truthy
    end

    it "is false when user is not in the owners list" do
      stranger = create(:user)
      service = create(:service)

      expect(service.owned_by?(stranger)).to be_falsy
    end
  end

  context "OMS validations" do
    subject { build(:service, omses: build_list(:resource_dedicated_oms, 2)) }
    it { should have_many(:omses) }
  end

  context "#available_omses" do
    subject { build(:service) }

    it "should return empty if there are no OMSes" do
      expect(subject.available_omses).to eq([])
    end

    context "when there are registered OMSes" do
      before do
        @global_oms = create(:oms)
        @default_oms = create(:default_oms)
        @provider_oms = create(:provider_group_oms)
        @resource_oms = create(:resource_dedicated_oms)
      end

      it "doesn't return if not associated" do
        subject.update!(providers: [@provider_oms.providers[0]])

        expect(subject.available_omses).to eq([@default_oms, @global_oms])
      end

      it "returns all associated" do
        subject.update!(resource_organisation: @provider_oms.providers[0])
        @resource_oms.update!(service: subject)

        expect(subject.available_omses).to eq([@default_oms, @resource_oms, @global_oms, @provider_oms])
      end
    end
  end

  context "#propagate_to_ess" do
    context "adds" do
      Service::PUBLIC_STATUSES.each do |public_status|
        it "a new #{public_status} service" do
          expect { create(:service, status: public_status) }.to have_enqueued_job(Ess::UpdateJob)
            .exactly(4)
            .times
            .with { |payload| expect(payload).to be_an_add_operation }
        end

        it "a service updated to #{public_status}" do
          service = create(:service)

          expect { service.update!(status: public_status) }.to have_enqueued_job(Ess::UpdateJob).with { |payload|
            expect(payload).to be_an_add_operation
          }
        end
      end

      it "an updated service" do
        service = create(:service)

        expect { service.update!(tagline: "new value") }.to have_enqueued_job(Ess::UpdateJob).with { |payload|
          expect(payload).to be_an_add_operation
        }
      end

      matcher :be_an_add_operation do
        match { |payload| expect(payload["action"]).to eq("update") }
      end
    end

    context "deletes" do
      Service::STATUSES
        .values
        .reject { |k| Service::PUBLIC_STATUSES.include?(k) }
        .each do |non_public_status|
          it "a new #{non_public_status} service" do
            provider = create(:provider)
            catalogue = create(:catalogue)
            expect do
              create(
                :service,
                resource_organisation: provider,
                providers: [provider],
                catalogue: catalogue,
                status: non_public_status
              )
            end.to have_enqueued_job(Ess::UpdateJob).with { |payload| expect(payload).to be_a_delete_operation }
          end

          it "a service updated to #{non_public_status}" do
            service = create(:service)

            expect { service.update!(status: non_public_status) }.to have_enqueued_job(Ess::UpdateJob).with { |payload|
              expect(payload).to be_a_delete_operation
            }
          end
        end

      it "an updated service" do
        service = create(:service, status: "deleted")

        expect { service.update!(tagline: "new value") }.to have_enqueued_job(Ess::UpdateJob).with { |payload|
          expect(payload).to be_a_delete_operation
        }
      end

      matcher :be_a_delete_operation do
        match { |payload| expect(payload["action"]).to eq("delete") }
      end
    end
  end
end
