# frozen_string_literal: true

require "rails_helper"

RSpec.describe Statistics::ServiceStatistics do
  subject(:statistics) { described_class.call(services, matomo:) }

  let(:matomo) do
    Matomo::Configuration.new(
      "MP_MATOMO_ENABLED" => "true",
      "MP_MATOMO_URL" => "https://matomo.example.org/",
      "MP_MATOMO_SITE_ID" => "12",
      "MP_MATOMO_TOKEN_AUTH" => "secret"
    )
  end
  # Two Offers, two Orders, one open access Project item, which is no Order,
  # an Opinion and 1250 Views.
  let(:service) do
    create(:service, pid: "21.T15999/abc", usage_counts_views: 1250).tap do |service|
      orders = create_list(:project_item, 2, offer: create(:offer, service:))
      create(:project_item, offer: create(:open_access_offer, service:))
      create(:service_opinion, project_item: orders.first)
    end
  end
  let(:services) { [service.reload] }

  it "gives the Service's figures" do
    expect(statistics.sole).to eq(
      pid: "21.T15999/abc", offers_count: 2, service_opinion_count: 1, project_items_count: 3,
      usage_counts_views: 1250, usage_counts_downloads: 2
    )
  end

  {
    "Matomo is off" => { "MP_MATOMO_ENABLED" => "false", "MP_MATOMO_TOKEN_AUTH" => "secret" },
    "MP_MATOMO_TOKEN_AUTH is not set" => {
      "MP_MATOMO_ENABLED" => "true",
      "MP_MATOMO_URL" => "https://matomo.example.org/",
      "MP_MATOMO_SITE_ID" => "12"
    }
  }.each do |reason, env|
    context "when #{reason}" do
      let(:matomo) { Matomo::Configuration.new(env) }

      it "gives no Views, as they aren't tracked" do
        expect(statistics.first).to include(usage_counts_views: nil, usage_counts_downloads: 2)
      end
    end
  end

  context "with several Services" do
    # No Order, one and two, in that order.
    let!(:services) do
      create_list(:service, 3)
        .each_with_index { |service, orders| create_list(:project_item, orders, offer: create(:offer, service:)) }
        .map(&:reload)
    end

    it "gives each Service its own figures, in the order given" do
      expect(statistics.pluck(:pid, :usage_counts_downloads)).to eq(services.map(&:pid).zip([0, 1, 2]))
    end

    it "counts the Orders of all of them in one query" do
      queries = []
      count_query = ->(*, payload) { queries << payload[:sql] unless payload[:name] == "SCHEMA" }
      ActiveSupport::Notifications.subscribed(count_query, "sql.active_record") { statistics }

      expect(queries.size).to eq(1)
    end
  end
end
