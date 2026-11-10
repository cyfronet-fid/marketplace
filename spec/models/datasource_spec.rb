# frozen_string_literal: true

require "rails_helper"

RSpec.describe Datasource, :backend do
  it "uses the Service model name for STI forms" do
    expect(described_class.model_name).to eq(Service.model_name)
    expect(described_class.type).to eq("Datasource")
  end

  it "keeps research product types as plain strings" do
    datasource = build(:datasource, research_product_types: ["ds_research_entity_type-research_data"])

    expect(datasource.research_product_types).to eq(["ds_research_entity_type-research_data"])
  end

  describe "pid" do
    # The factory builds a Service with type "Datasource"; reload to get the Datasource class
    let(:datasource) { described_class.find(create(:datasource).id) }
    let(:uuid) { /\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/ }

    context "when pid is nil and the datasource has a source" do
      before do
        datasource.sources.build(source_type: :eosc_registry, eid: "datasource-eid")
        datasource.pid = nil
      end

      it "uses the source eid" do
        expect { datasource.valid? }.to change(datasource, :pid).from(nil).to("datasource-eid")
      end
    end

    context "when pid is nil and the datasource has no source" do
      before { datasource.pid = nil }

      it "assigns a generated pid" do
        expect { datasource.valid? }.to change(datasource, :pid).from(nil).to(match(uuid))
      end
    end

    context "when pid is blank" do
      before { datasource.pid = "  " }

      it "replaces it with a generated pid" do
        expect { datasource.valid? }.to change(datasource, :pid).from("  ").to(match(uuid))
      end
    end

    context "when pid is nil and validations are skipped" do
      before do
        datasource.pid = nil
        datasource.save(validate: false)
      end

      it "persists a generated pid" do
        expect(datasource.reload.pid).to match(uuid)
      end
    end

    context "when pid is present" do
      before do
        datasource.sources.build(source_type: :eosc_registry, eid: "datasource-eid")
        datasource.pid = "custom-pid"
      end

      it "keeps the given pid" do
        expect { datasource.valid? }.not_to change(datasource, :pid).from("custom-pid")
      end
    end
  end
end
