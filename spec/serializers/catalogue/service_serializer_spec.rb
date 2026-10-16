# frozen_string_literal: true

require "rails_helper"

RSpec.describe Catalogue::ServiceSerializer, backend: true do
  subject(:data) { described_class.new(service).as_json }

  let(:service) do
    create(
      :service,
      scientific_domains: scientific_domains,
      categories: categories,
      trls: trls,
      target_users: target_users
    )
  end

  let(:domain) { create(:scientific_domain) }
  let(:subdomain) { create(:scientific_domain, parent: domain) }
  let(:other_subdomain) { create(:scientific_domain, parent: domain) }
  let(:scientific_domains) { [subdomain] }

  let(:supercategory) { create(:category) }
  let(:category) { create(:category, parent: supercategory) }
  let(:subcategory) { create(:category, parent: category) }
  let(:categories) { [subcategory] }

  let(:trl) { create(:trl, eid: "trl-9", name: "9 - actual system proven in operational environment") }
  let(:trls) { [trl] }

  let(:researchers) { create(:target_user, eid: "target_user-researchers") }
  let(:target_users) { [researchers] }

  describe "scientificDomains" do
    subject(:scientific_domains_data) { data["scientificDomains"] }

    it "pairs the subdomain with its domain" do
      expect(scientific_domains_data).to eq(
        [{ "scientificDomain" => domain.eid, "scientificSubdomain" => subdomain.eid }]
      )
    end

    context "when the service is linked to both the domain and its subdomain" do
      let(:scientific_domains) { [domain, subdomain] }

      it "publishes only the pair" do
        expect(scientific_domains_data).to eq(
          [{ "scientificDomain" => domain.eid, "scientificSubdomain" => subdomain.eid }]
        )
      end
    end

    context "when the service is linked to many subdomains of one domain" do
      let(:scientific_domains) { [subdomain, other_subdomain] }

      it "publishes a pair for each subdomain" do
        expect(scientific_domains_data).to contain_exactly(
          { "scientificDomain" => domain.eid, "scientificSubdomain" => subdomain.eid },
          { "scientificDomain" => domain.eid, "scientificSubdomain" => other_subdomain.eid }
        )
      end
    end

    context "when the service is linked only to the domain" do
      let(:scientific_domains) { [domain] }

      it "publishes the domain without a subdomain" do
        expect(scientific_domains_data).to eq([{ "scientificDomain" => domain.eid }])
      end
    end

    context "when the subdomain has no eid" do
      let(:subdomain) { create(:scientific_domain, parent: domain, eid: "") }

      it "omits it" do
        expect(scientific_domains_data).to eq([])
      end
    end

    context "when the domain of the subdomain has no eid" do
      let(:domain) { create(:scientific_domain, eid: "") }

      it "omits the pair" do
        expect(scientific_domains_data).to eq([])
      end
    end
  end

  describe "categories" do
    subject(:categories_data) { data["categories"] }

    it "pairs the subcategory with its category" do
      expect(categories_data).to eq([{ "category" => category.eid, "subcategory" => subcategory.eid }])
    end

    context "when the service is linked to both the category and its subcategory" do
      let(:categories) { [category, subcategory] }

      it "publishes only the pair" do
        expect(categories_data).to eq([{ "category" => category.eid, "subcategory" => subcategory.eid }])
      end
    end

    context "when the service is linked only to the category" do
      let(:categories) { [category] }

      it "publishes the category without a subcategory" do
        expect(categories_data).to eq([{ "category" => category.eid }])
      end
    end

    context "when the service is linked only to the supercategory" do
      let(:categories) { [supercategory] }

      it "omits the supercategory" do
        expect(categories_data).to eq([])
      end
    end
  end

  describe "trl" do
    it "publishes the vocabulary id instead of the label" do
      expect(data["trl"]).to eq("trl-9")
    end

    context "when the service has no trl" do
      let(:trls) { [] }

      it "publishes null" do
        expect(data["trl"]).to be_nil
      end
    end

    context "when the trl has no eid" do
      let(:trl) { create(:trl, eid: "") }

      it "publishes null" do
        expect(data["trl"]).to be_nil
      end
    end
  end

  describe "targetUsers" do
    it "publishes the vocabulary ids" do
      expect(data["targetUsers"]).to eq(["target_user-researchers"])
    end

    context "when a target user has no eid" do
      let(:target_users) { [researchers, create(:target_user, eid: "")] }

      it "omits it" do
        expect(data["targetUsers"]).to eq(["target_user-researchers"])
      end
    end
  end
end
