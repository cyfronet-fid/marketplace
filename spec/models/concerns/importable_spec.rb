# frozen_string_literal: true

require "rails_helper"

RSpec.describe Importable do
  subject(:importer) { Class.new { include Importable }.new }

  describe "#map_link" do
    it "maps HTTP and HTTPS multimedia URLs" do
      expect(importer.map_link("https://example.org/video")).to have_attributes(
        name: "",
        url: "https://example.org/video"
      )
    end

    it "maps a hash containing a valid multimedia URL" do
      expect(
        importer.map_link("multimediaName" => "Video", "multimediaURL" => "http://example.org/video")
      ).to have_attributes(name: "Video", url: "http://example.org/video")
    end

    it "rejects a hash containing a non-HTTP multimedia URL" do
      expect(importer.map_link("multimediaName" => "Video", "multimediaURL" => "javascript:alert(1)")).to be_nil
    end
  end

  describe "#map_scientific_domains" do
    subject(:mapped) { importer.map_scientific_domains(domains) }

    let(:domain) { create(:scientific_domain, eid: "scientific_domain-natural_sciences") }
    let(:subdomain) do
      create(:scientific_domain, parent: domain, eid: "scientific_subdomain-natural_sciences-biological_sciences")
    end
    let(:domains) { ["scientificDomain" => domain.eid, "scientificSubdomain" => subdomain.eid] }

    it "links the subdomain of a registry pair" do
      expect(mapped).to contain_exactly(subdomain)
    end

    context "when the pair has no subdomain" do
      let(:domains) { ["scientificDomain" => domain.eid, "scientificSubdomain" => ""] }

      it "links the domain" do
        expect(mapped).to contain_exactly(domain)
      end
    end

    context "when given plain eids" do
      let(:domains) { [subdomain.eid] }

      it "links them" do
        expect(mapped).to contain_exactly(subdomain)
      end
    end

    context "when empty" do
      let(:domains) { nil }

      it { is_expected.to eq([]) }
    end
  end

  describe "#map_categories" do
    subject(:mapped) { importer.map_categories(categories) }

    let(:category) { create(:category, eid: "category-data") }
    let(:subcategory) { create(:category, parent: category, eid: "subcategory-data-analysis") }
    let(:categories) { ["category" => category.eid, "subcategory" => subcategory.eid] }

    it "links the subcategory of a registry pair" do
      expect(mapped).to contain_exactly(subcategory)
    end

    context "when the pair has no subcategory" do
      let(:categories) { ["category" => category.eid] }

      it "links the category" do
        expect(mapped).to contain_exactly(category)
      end
    end
  end
end
