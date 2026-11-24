# frozen_string_literal: true

require "rails_helper"

describe "rake matomo:sync_views", type: :task do
  let(:service) { create(:service) }
  let(:matomo_env) do
    {
      "MP_MATOMO_ENABLED" => "true",
      "MP_MATOMO_URL" => "https://matomo.example.org",
      "MP_MATOMO_SITE_ID" => "12",
      "MP_MATOMO_TOKEN_AUTH" => "view-token"
    }
  end
  # The days Matomo answers for; a request for other days fails the example.
  let(:reported_dates) { "2026-01-01,2026-01-31" }

  before do
    task.reenable
    allow(Mp::Application.config).to receive(:matomo).and_return(Matomo::Configuration.new(matomo_env))
    stub_request(:post, "https://matomo.example.org/index.php").with(
      body: hash_including("date" => reported_dates)
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

  it "rejects a first day after the last" do
    expect { task.invoke("2026-01-31", "2026-01-01") }.to raise_error(ArgumentError, /is after the last day/)
  end

  context "with a single day" do
    let(:reported_dates) { "2026-01-15,2026-01-15" }

    it "syncs the Views of that day" do
      task.invoke("2026-01-15", "2026-01-15")

      expect(service.reload.usage_counts_views).to eq(7)
    end
  end

  # Matomo answers for no days here, so a sync would fail the example with a
  # WebMock error instead of the SystemExit of abort.
  context "without MP_MATOMO_TOKEN_AUTH" do
    let(:matomo_env) { super().except("MP_MATOMO_TOKEN_AUTH") }
    let(:reported_dates) { nil }

    it "stops with a message, before it asks Matomo" do
      expect { task.invoke("2026-01-01", "2026-01-31") }.to raise_error(SystemExit).and output(
        /MP_MATOMO_TOKEN_AUTH is not set/
      ).to_stderr
    end
  end

  context "when Matomo is off" do
    let(:matomo_env) { { "MP_MATOMO_ENABLED" => "false", "MP_MATOMO_TOKEN_AUTH" => "view-token" } }
    let(:reported_dates) { nil }

    it "stops with a message, before it asks Matomo" do
      expect { task.invoke("2026-01-01", "2026-01-31") }.to raise_error(SystemExit).and output(
        /MP_MATOMO_ENABLED is not true/
      ).to_stderr
    end
  end
end
