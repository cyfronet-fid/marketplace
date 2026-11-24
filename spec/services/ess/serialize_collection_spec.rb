# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ess::SerializeCollection, :backend do
  subject(:json) { described_class.call(records, serializer) }

  before { allow(Statistics::OrderCounts).to receive(:call).and_call_original }

  context "with Services" do
    let(:serializer) { Ess::ServiceSerializer }
    let(:records) { create_list(:service, 2) }

    before { create_list(:project_item, 2, offer: create(:offer, service: records.first)) }

    it "sends the Orders of each as usage_counts_downloads" do
      expect(json.pluck(:usage_counts_downloads)).to eq([2, 0])
    end

    it "counts the Orders of the whole collection in one call" do
      json

      expect(Statistics::OrderCounts).to have_received(:call).once.with(records)
    end
  end

  context "with Datasources" do
    let(:serializer) { Ess::DatasourceSerializer }
    let(:records) { [create(:datasource)] }

    before { create(:project_item, offer: create(:offer, service: records.first)) }

    it "sends the Orders of each as usage_counts_downloads" do
      expect(json.pluck(:usage_counts_downloads)).to eq([1])
    end
  end

  context "with records other than Services" do
    let(:serializer) { Ess::ProviderSerializer }
    let(:records) { [create(:provider)] }

    it "serializes each as its serializer does" do
      expect(json).to eq([Ess::ProviderSerializer.new(records.first).as_json])
    end

    it "counts no Orders" do
      json

      expect(Statistics::OrderCounts).not_to have_received(:call)
    end
  end
end
