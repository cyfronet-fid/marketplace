# frozen_string_literal: true

require "rails_helper"

describe ProjectItem::OnCreated::PublishCoexistence, backend: true do
  it "doesn't enqueue if empty" do
    project = double(Project)
    expect(project).to receive(:project_items).and_return([])
    allow(Jms::PublishJob).to receive(:perform_later)

    described_class.call(project)

    expect(Jms::PublishJob).not_to have_received(:perform_later)
  end

  it "doesn't enqueue if services not :eosc_registry" do
    project = double(Project)
    pi1 = double(ProjectItem, service: double(Service, upstream: nil))
    pi2 = double(ProjectItem, service: double(Service, upstream: nil))
    expect(project).to receive(:project_items).and_return([pi1, pi2])
    allow(Jms::PublishJob).to receive(:perform_later)

    described_class.call(project)

    expect(Jms::PublishJob).not_to have_received(:perform_later)
  end

  it "enqueues if service with upstream.eosc_registry?" do
    project = double(Project, id: 1)
    pi1 =
      double(ProjectItem, service: double(Service, pid: "foo", upstream: double(ServiceSource, eosc_registry?: true)))
    expect(project).to receive(:project_items).and_return([pi1])
    allow(Jms::PublishJob).to receive(:perform_later)

    described_class.call(project)

    expect(Jms::PublishJob).to have_received(:perform_later)
  end

  it "de-duplicates services" do
    project = double(Project, id: 1)
    service = double(Service, pid: "foo", upstream: double(ServiceSource, eosc_registry?: true))
    pi1 = double(ProjectItem, service: service)
    pi2 = double(ProjectItem, service: service)
    expect(project).to receive(:project_items).and_return([pi1, pi2])
    allow(Jms::PublishJob).to receive(:perform_later) do |message|
      expect(message[:coexisting_resources]).to eq(["foo"])
    end

    described_class.call(project)

    expect(Jms::PublishJob).to have_received(:perform_later)
  end
end
