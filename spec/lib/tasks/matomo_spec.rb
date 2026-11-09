# frozen_string_literal: true

require "rails_helper"

describe "rake matomo:sync_views", type: :task do
  let(:service) { create(:service) }

  before do
    task.reenable
    allow(Mp::Application.config).to receive(:matomo).and_return(
      Matomo::Configuration.new(
        "MP_MATOMO_ENABLED" => "true",
        "MP_MATOMO_URL" => "https://matomo.example.org",
        "MP_MATOMO_SITE_ID" => "12",
        "MP_MATOMO_TOKEN_AUTH" => "view-token"
      )
    )
    stub_request(:post, "https://matomo.example.org/index.php").with(
      body: hash_including("date" => "2026-01-01,2026-01-31")
    ).to_return(
      status: 200,
      body: { "2026-01-15" => ["label" => "#{service.pid} - View", "nb_events" => 7, "nb_visits" => 5] }.to_json,
      headers: { "Content-Type" => "application/json" }
    )
  end

  it "preloads the Rails environment" do
    expect(task.prerequisites).to include "environment"
  end

  it "syncs the Views of the given days" do
    task.invoke("2026-01-01", "2026-01-31")

    expect(service.reload.usage_counts_views).to eq(7)
  end

  it "requires both dates" do
    expect { task.invoke("2026-01-01") }.to raise_error(ArgumentError, /matomo:sync_views\[/)
  end
end
