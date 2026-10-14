# frozen_string_literal: true

require "rails_helper"
require_relative "publishable"

RSpec.describe Service, :backend do
  include_examples "publishable"

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:description) }
  it { is_expected.to validate_presence_of(:rating) }

  it { is_expected.to have_many(:providers) }
  it { is_expected.to have_many(:categorizations).dependent(:destroy) }
  it { is_expected.to have_many(:offers).dependent(:restrict_with_error) }
  it { is_expected.to have_many(:categories) }
  it { is_expected.to have_many(:service_scientific_domains).dependent(:destroy) }
  it { is_expected.to have_many(:service_vocabularies).dependent(:destroy) }

  it { is_expected.to belong_to(:upstream).required(false) }

  it "allows scientific domains to be omitted" do
    expect(build(:service, scientific_domains: [])).to be_valid
  end

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

  describe "#owned_by?" do
    it "is true when user is in the owners list" do
      owner = create(:user)
      service = create(:service, owners: [owner])

      expect(service.owned_by?(owner)).to be_truthy
    end

    it "is false when user is not in the owners list" do
      stranger = create(:user)
      service = create(:service)

      expect(service.owned_by?(stranger)).to be_falsy
    end
  end

  context "databus publishing" do
    before { clear_enqueued_jobs }

    it "publishes a destroy event when service is soft-deleted" do
      service = create(:service)
      clear_enqueued_jobs

      expect { service.update!(status: :deleted) }.to have_enqueued_job(Jms::PublishJob).with(
        hash_including("cud" => "destroy", "model" => "Service"),
        :mp_db_events
      )
    end
  end

  context "OMS validations" do
    subject { build(:service, omses: build_list(:resource_dedicated_oms, 2)) }

    it { is_expected.to have_many(:omses) }
  end

  describe "#available_omses" do
    subject { build(:service) }

    it "returns empty if there are no OMSes" do
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

  describe "#propagate_to_ess" do
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

        expect { service.update!(description: "new value") }.to have_enqueued_job(Ess::UpdateJob).with { |payload|
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

        expect { service.update!(description: "new value") }.to have_enqueued_job(Ess::UpdateJob).with { |payload|
          expect(payload).to be_a_delete_operation
        }
      end

      matcher :be_a_delete_operation do
        match { |payload| expect(payload["action"]).to eq("delete") }
      end
    end
  end

  describe "pid" do
    let(:service) { build(:service) }

    context "when pid is nil" do
      before { service.pid = nil }

      it "assigns a generated pid" do
        expect { service.valid? }.to change(service, :pid).from(nil).to(be_present)
      end
    end

    context "when pid is blank" do
      before { service.pid = "  " }

      it "assigns a generated pid" do
        expect { service.valid? }.to change(service, :pid).from("  ").to(be_present)
      end
    end

    context "when pid is nil and validations are skipped" do
      before do
        service.pid = nil
        service.save(validate: false)
      end

      it "persists a generated pid" do
        expect(service.reload.pid).to be_present
      end
    end

    context "when pid is blank and validations are skipped" do
      before do
        service.pid = "  "
        service.save(validate: false)
      end

      it "persists a generated pid" do
        expect(service.reload.pid).to be_present
      end
    end

    context "when pid is present" do
      let(:service) { build(:service, pid: "custom-pid") }

      it "keeps the given pid" do
        expect { service.valid? }.not_to change(service, :pid).from("custom-pid")
      end
    end

    context "when pid is already taken by another service" do
      let(:service) { build(:service, pid: "taken-pid") }

      before { create(:service, pid: "taken-pid") }

      it "is invalid" do
        expect(service).not_to be_valid
      end

      it "reports the pid as taken" do
        service.valid?
        expect(service.errors[:pid]).to include("has already been taken")
      end

      it "is rejected by the database when validations are skipped" do
        expect { service.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
      end
    end
  end
end
