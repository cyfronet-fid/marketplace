# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::Search::ServicesController, type: :controller do
  describe "#facets (private)" do
    # Build a minimal stub that responds to aggregations
    let(:search_stub) do
      Struct.new(:aggregations).new(
        {
          "categories" => {
            "buckets" => [{ "key" => 1, "doc_count" => 3 }]
          },
          "scientific_domains" => {
            "buckets" => [{ "key" => 2, "doc_count" => 4 }]
          },
          "providers" => {
            "buckets" => [{ "key" => 10, "doc_count" => 2 }]
          },
          "platforms" => {
            "buckets" => [{ "key" => 20, "doc_count" => 1 }]
          },
          "research_activities" => {
            "buckets" => [{ "key" => 30, "doc_count" => 5 }]
          },
          "dedicated_for" => {
            "buckets" => [{ "key" => 40, "doc_count" => 6 }]
          },
          "order_type" => {
            "buckets" => [{ "key" => "open_access", "doc_count" => 7 }]
          },
          "rating" => {
            "buckets" => [{ "key" => "4", "doc_count" => 8 }]
          }
        }
      )
    end

    before do
      # Categories tree with one node id:1 and SD tree with one node id:2
      fake_category = instance_double("Category", id: 1, eid: "cat-1", name: "Category 1")
      fake_sd = instance_double("ScientificDomain", id: 2, eid: "sd-2", name: "SD 2")

      allow(Category).to receive(:arrange).with(order: :name).and_return({ fake_category => {} })
      allow(ScientificDomain).to receive(:arrange).with(order: :name).and_return({ fake_sd => {} })

      # Providers, Target Users, Platforms, Research Activities
      allow(Provider).to receive(:pluck).with(:id, :name, :pid).and_return([[10, "Prov A", "prov-a"]])
      allow(TargetUser).to receive(:pluck).with(:id, :name, :eid).and_return([[40, "Scientists", "scientists"]])
      allow(Platform).to receive(:pluck).with(:id, :name, :eid).and_return([[20, "Web", "web"]])
      allow(Vocabulary::ResearchActivity).to receive(:pluck).with(:id, :name, :eid).and_return([[30, "RA", "ra"]])
    end

    it "returns non-zero counts when aggregations have string keys" do
      controller_instance = described_class.new

      result = controller_instance.send(:facets, search_stub)

      expect(result[:categories].first[:count]).to eq(3)
      expect(result[:scientific_domains].first[:count]).to eq(4)
      expect(result[:providers].first[:count]).to eq(2)
      expect(result[:platforms].first[:count]).to eq(1)
      expect(result[:research_activities].first[:count]).to eq(5)
      expect(result[:target_users].first[:count]).to eq(6)

      rating_entry = result[:rating].find { |h| h[:eid] == "4" }
      expect(rating_entry[:count]).to eq(8)

      order_type_entry = result[:order_type].find { |h| h[:eid] == "open_access" }
      expect(order_type_entry[:count]).to eq(7)
    end
  end
end
