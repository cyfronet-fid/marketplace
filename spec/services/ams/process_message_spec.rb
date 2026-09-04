# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ams::ProcessMessage do
  subject(:call) { described_class.call(subscription_name, message: message) }

  context "when creating or updating a resource" do
    let(:payload) { { "id" => "123" } }
    let(:modified_at) { Time.zone.at(Rational(1_700_000_000_000, 1000)) }
    let(:message) do
      {
        "data" => {
          resource_key => payload,
          "active" => true,
          "suspended" => false,
          "metadata" => { "modifiedAt" => 1_700_000_000_000 }
        }
      }
    end

    {
      "catalogue" => Catalogue::PcCreateOrUpdateJob,
      "datasource" => Datasource::PcCreateOrUpdateJob,
      "deployable_application" => DeployableService::PcCreateOrUpdateJob,
      "interoperability_record" => Guideline::PcCreateOrUpdateJob,
      "organisation" => Provider::PcCreateOrUpdateJob,
      "service" => Service::PcCreateOrUpdateJob
    }.each do |resource, job_klass|
      context "when the resource is '#{resource}'" do
        let(:subscription_name) { "mp-#{resource}-create" }
        let(:resource_key) { resource.camelize(:lower) }

        it "enqueues #{job_klass} with the payload, status and modified_at" do
          expect { call }.to have_enqueued_job(job_klass).with(payload, :published, modified_at)
        end
      end
    end

    context "when the subscription name has no prefix" do
      let(:subscription_name) { "service-update" }
      let(:resource_key) { "service" }

      it "still parses the resource and action correctly" do
        expect { call }.to have_enqueued_job(Service::PcCreateOrUpdateJob).with(payload, :published, modified_at)
      end
    end

    context "when the message has no modifiedAt metadata" do
      let(:subscription_name) { "mp-service-create" }
      let(:resource_key) { "service" }
      let(:message) { { "data" => { "service" => payload, "active" => true, "suspended" => false } } }

      it "falls back to the current time" do
        expect { call }
          .to have_enqueued_job(Service::PcCreateOrUpdateJob).with(payload, :published, kind_of(ActiveSupport::TimeWithZone))
      end
    end
  end

  context "when deleting a resource" do
    let(:message) { { "data" => { "id" => "123" } } }

    {
      "datasource" => Datasource::DeleteJob,
      "deployable_application" => DeployableService::DeleteJob,
      "interoperability_record" => Guideline::DeleteJob,
      "organisation" => Provider::DeleteJob,
      "service" => Service::DeleteJob
    }.each do |resource, job_klass|
      context "when the resource is '#{resource}'" do
        let(:subscription_name) { "mp-#{resource}-delete" }

        it "enqueues #{job_klass} with the id" do
          expect { call }.to have_enqueued_job(job_klass).with("123")
        end
      end
    end
  end

  context "when no job is registered for the resource/action pair" do
    let(:message) { { "data" => { "id" => "123" } } }

    before { allow(Ams::Logger).to receive(:warn) }

    context "when the resource is unknown" do
      let(:subscription_name) { "mp-infra_service-create" }

      it "logs a warning" do
        call
        expect(Ams::Logger).to have_received(:warn).with("Unsupported 'create' for resource 'infra_service'")
      end
    end

    context "when the resource has no delete job" do
      let(:subscription_name) { "mp-catalogue-delete" }

      it "logs a warning" do
        call
        expect(Ams::Logger).to have_received(:warn).with("Unsupported 'delete' for resource 'catalogue'")
      end
    end
  end

  context "when the action is neither create, update nor delete" do
    let(:subscription_name) { "mp-service-archive" }
    let(:message) { { "data" => { "id" => "123" } } }

    it "returns nil without enqueuing a job" do
      expect(call).to be_nil
    end
  end
end
