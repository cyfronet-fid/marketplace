# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ess::Add, :backend do
  let!(:service) { create(:service) }
  let!(:datasource) { create(:datasource) }

  context "when a datasource is added outside pl" do
    before do
      clear_enqueued_jobs
      described_class.call(datasource, "data source")
    end

    it "serializes it as a service" do
      expect(Ess::UpdateJob).to have_been_enqueued.with(
        hash_including("data_type" => "data source", "data" => Ess::ServiceSerializer.new(datasource).as_json.as_json)
      )
    end
  end

  context "when a datasource is added on pl" do
    before do
      allow(Mp::Variant).to receive(:pl?).and_return(true)
      clear_enqueued_jobs
      described_class.call(datasource, "data source")
    end

    it "serializes it with the datasource profile" do
      expect(Ess::UpdateJob).to have_been_enqueued.with(
        hash_including("data_type" => "data source", "data" => Ess::DatasourceSerializer.new(datasource).as_json.as_json)
      )
    end
  end

  context "when offers are propagated" do
    let!(:offer) { create(:offer, service: service) }

    before do
      clear_enqueued_jobs
      described_class.call(service.reload, "service")
    end

    it "re-sends the published offer" do
      expect(Ess::UpdateJob).to have_been_enqueued.with(
        hash_including("data_type" => "offer", "data" => hash_including("id" => offer.id))
      )
    end
  end

  context "when offers are not propagated" do
    let!(:offer) { create(:offer, service: service) }

    before do
      clear_enqueued_jobs
      described_class.call(service.reload, "service", propagate_offers: false)
    end

    it "sends only the service" do
      expect(Ess::UpdateJob).not_to have_been_enqueued.with(
        hash_including("data_type" => "offer", "data" => hash_including("id" => offer.id))
      )
    end
  end
end
