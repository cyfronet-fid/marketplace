# frozen_string_literal: true

require "rails_helper"

RSpec.describe Matomo::SyncViewsJob, type: :job do
  let(:service) { create(:service) }
  let(:token) { "view-token" }
  # Events.getName by day, flattened to "<event name> - <event action>" rows,
  # as Matomo 5 returns it; Matomo sends some numbers as strings.
  let(:report) do
    {
      "2026-11-07" => [],
      "2026-11-08" => ["label" => "#{service.pid} - View", "nb_events" => 3, "nb_visits" => 2],
      "2026-11-09" => [
        { "label" => "#{service.pid} - View", "nb_events" => "1", "nb_visits" => "1" },
        { "label" => "#{service.pid} - AddToProject", "nb_events" => "1", "nb_visits" => "1" }
      ]
    }
  end
  let(:statistics) { ViewStatistic.order(:date).pluck(:viewable_type, :viewable_id, :date, :views, :visits) }

  around { |example| travel_to(Time.zone.local(2026, 11, 9, 2, 15)) { example.run } }

  before do
    allow(Mp::Application.config).to receive(:matomo).and_return(
      Matomo::Configuration.new(
        "MP_MATOMO_ENABLED" => "true",
        "MP_MATOMO_URL" => "https://matomo.example.org",
        "MP_MATOMO_SITE_ID" => "12",
        "MP_MATOMO_TOKEN_AUTH" => token
      )
    )
    stub_request(:post, "https://matomo.example.org/index.php").to_return(
      status: 200,
      body: report.to_json,
      headers: { "Content-Type" => "application/json" }
    )
  end

  it "stores the Views and visits of each service per day" do
    described_class.perform_now

    expect(statistics).to eq(
      [["Service", service.id, Date.new(2026, 11, 8), 3, 2], ["Service", service.id, Date.new(2026, 11, 9), 1, 1]]
    )
  end

  it "updates the Views of a day synced before" do
    service.view_statistics.create!(date: Date.new(2026, 11, 9), views: 0, visits: 0)

    expect { described_class.perform_now }.to change { service.view_statistics.find_by(date: "2026-11-09").views }
      .from(0).to(1)
  end

  it "gives the same rows and totals on a second run" do
    described_class.perform_now

    expect { described_class.perform_now }.not_to change { [statistics, service.reload.usage_counts_views] }
  end

  context "with a datasource" do
    let(:service) { create(:datasource) }

    it "stores its Views as those of a service" do
      described_class.perform_now

      expect(service.reload.view_statistics.sum(:views)).to eq(4)
    end
  end

  describe "the request to Matomo" do
    let(:report_params) do
      {
        "module" => "API",
        "method" => "Events.getName",
        "idSite" => "12",
        "period" => "day",
        "date" => "2026-11-07,2026-11-09",
        "flat" => "1",
        "filter_limit" => "-1"
      }
    end

    before { described_class.perform_now }

    it "asks for the flattened event names of the last three days without a row limit" do
      expect(a_request(:post, "https://matomo.example.org/index.php").with(body: hash_including(report_params)))
        .to have_been_made
    end

    # A segment would select whole visits and count their other events too.
    it "doesn't narrow the report with a segment" do
      expect(
        a_request(:post, "https://matomo.example.org/index.php").with do |request|
          !URI.decode_www_form(request.body).to_h.key?("segment")
        end
      ).to have_been_made
    end

    # The stubbed URL has no query, so a token in the URL would not match it.
    it "sends the token in the POST body, never in the URL" do
      expect(a_request(:post, "https://matomo.example.org/index.php").with(body: hash_including("token_auth" => token)))
        .to have_been_made
    end
  end

  context "with View events of no known record" do
    let(:report) { { "2026-11-09" => ["label" => "21.T15999/gone - View", "nb_events" => 2, "nb_visits" => 1] } }

    before { allow(Rails.logger).to receive(:warn) }

    it "logs their names" do
      described_class.perform_now

      expect(Rails.logger).to have_received(:warn).with(%r{21\.T15999/gone})
    end

    it "skips them" do
      described_class.perform_now

      expect(statistics).to be_empty
    end
  end

  describe "usage_counts_views" do
    before { service.view_statistics.create!(date: Date.new(2026, 10, 1), views: 10, visits: 4) }

    it "sums the Views of every day of a service" do
      expect { described_class.perform_now }.to change { service.reload.usage_counts_views }.from(0).to(14)
    end

    context "with a service with no Views" do
      let(:unviewed) { create(:service, usage_counts_views: 42) }

      it "sets it to 0" do
        expect { described_class.perform_now }.to change { unviewed.reload.usage_counts_views }.from(42).to(0)
      end
    end
  end

  context "without a reporting token" do
    let(:token) { nil }

    before { allow(Rails.logger).to receive(:warn) }

    it "doesn't call Matomo" do
      described_class.perform_now

      expect(a_request(:post, "https://matomo.example.org/index.php")).not_to have_been_made
    end

    it "logs a warning" do
      described_class.perform_now

      expect(Rails.logger).to have_received(:warn).with(/MP_MATOMO_TOKEN_AUTH/)
    end
  end

  describe "failures, which Sidekiq retries" do
    context "with a Matomo error result" do
      let(:report) { { result: "error", message: "Unable to authenticate with the provided token." } }

      it "raises Matomo's message" do
        expect { described_class.perform_now }.to raise_error(Matomo::ReportingClient::Error, /Unable to authenticate/)
      end
    end

    context "with an HTTP error" do
      before { stub_request(:post, "https://matomo.example.org/index.php").to_return(status: 502) }

      it "raises" do
        expect { described_class.perform_now }.to raise_error(Matomo::ReportingClient::Error, /502/)
      end
    end

    context "with a timeout" do
      before { stub_request(:post, "https://matomo.example.org/index.php").to_timeout }

      it "raises" do
        expect { described_class.perform_now }.to raise_error(Matomo::ReportingClient::Error)
      end
    end

    context "with a response that isn't JSON" do
      before { stub_request(:post, "https://matomo.example.org/index.php").to_return(body: "<html>Matomo</html>") }

      it "raises" do
        expect { described_class.perform_now }.to raise_error(Matomo::ReportingClient::Error)
      end
    end
  end

  describe "offers" do
    let(:offer) { create(:offer, service: service, usage_counts_views: 42) }

    it "carry the usage_counts_views of their service" do
      expect { described_class.perform_now }.to change { offer.reload.usage_counts_views }.from(42).to(4)
    end
  end
end
