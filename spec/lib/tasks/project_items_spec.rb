# frozen_string_literal: true

require "rails_helper"

describe "rake project_items:repair_counts", type: :task do
  let(:service) { create(:service, project_items_count: 7) }
  let(:offer) { create(:offer, service: service, project_items_count: 7) }
  let(:bundle) { create(:bundle, main_offer: offer, service: service, project_items_count: 7) }

  before do
    task.reenable
    create(:project_item, offer: offer, bundle: bundle)
  end

  it "preloads the Rails environment" do
    expect(task.prerequisites).to include "environment"
  end

  it "recounts the service's project items" do
    expect { task.invoke }.to output.to_stdout.and change { service.reload.project_items_count }.to(1)
  end

  it "recounts the offer's project items" do
    expect { task.invoke }.to output.to_stdout.and change { offer.reload.project_items_count }.to(1)
  end

  it "recounts the bundle's project items" do
    expect { task.invoke }.to output.to_stdout.and change { bundle.reload.project_items_count }.to(1)
  end
end
