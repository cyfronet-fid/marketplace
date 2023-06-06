# frozen_string_literal: true

require "rails_helper"

RSpec.describe Service::DeleteJob, backend: true do
  let(:service) { create(:service) }
  let(:source) { create(:service_source, service: service) }
  let(:delete_service) { instance_double(Service::Delete) }

  it "triggers ready process for project_item" do
    allow(Service::Delete).to receive(:new).with(service.id).and_return(delete_service)
    expect(delete_service).to receive(:call)
    described_class.perform_now(service.id)
  end

  it "triggers ready process for project_item" do
    ActiveJob::Base.queue_adapter = :test
    expect { described_class.perform_later(service.id) }.to have_enqueued_job.on_queue("pc_subscriber")
  end
end
