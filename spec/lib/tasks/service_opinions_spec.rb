# frozen_string_literal: true

require "rails_helper"

describe "rake service_opinions:repair_counts", type: :task do
  let(:service) { create(:service) }
  let!(:unrated) { create(:service, service_opinion_count: 3, rating: 2.0) }

  before do
    task.reenable
    offer = create(:offer, service:)
    create(:service_opinion, project_item: create(:project_item, offer:), service_rating: 4)
    create(:service_opinion, project_item: create(:project_item, offer:), service_rating: 5)
    # Counters that drifted before Opinions were counted from the rows.
    service.update_columns(service_opinion_count: 7, rating: 1.0) # rubocop:disable Rails/SkipsModelValidations
  end

  it "preloads the Rails environment" do
    expect(task.prerequisites).to include "environment"
  end

  it "recounts a drifted count and rating from the Opinions" do
    expect { task.invoke }.to output.to_stdout.and change {
      [service.reload.service_opinion_count, service.rating]
    }.to([2, 4.5])
  end

  it "sets both to 0 for a Service without Opinions" do
    expect { task.invoke }.to output.to_stdout.and change {
      [unrated.reload.service_opinion_count, unrated.rating]
    }.to([0, 0])
  end

  it "logs the old and new values of each Service" do
    expect { task.invoke }.to output(
      /\(#{service.id}\): service_opinion_count 7 => 2, rating 1\.0 => 4\.5$/
    ).to_stdout
  end
end
