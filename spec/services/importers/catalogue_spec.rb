# frozen_string_literal: true

require "rails_helper"

RSpec.describe Importers::Catalogue, :backend do
  subject(:imported) { described_class.call(data, synchronized_at) }

  let(:data) { {} }
  let(:synchronized_at) { Time.current.to_i }

  context "with simple pass-through fields" do
    let(:data) do
      {
        "id" => "catalogue-pid",
        "name" => "Test catalogue",
        "description" => "Test description",
        "webpage" => "https://example.org",
        "tags" => %w[a b]
      }
    end

    it "maps id to pid" do
      expect(imported[:pid]).to eq("catalogue-pid")
    end

    it "maps name" do
      expect(imported[:name]).to eq("Test catalogue")
    end

    it "maps description" do
      expect(imported[:description]).to eq("Test description")
    end

    it "maps webpage to website" do
      expect(imported[:website]).to eq("https://example.org")
    end

    it "maps tags to tag_list" do
      expect(imported[:tag_list]).to eq(%w[a b])
    end

    it "always sets status to published" do
      expect(imported[:status]).to eq(:published)
    end

    it "passes synchronized_at through unchanged" do
      expect(imported[:synchronized_at]).to eq(synchronized_at)
    end
  end

  context "when tags is absent" do
    it "builds an empty tag_list" do
      expect(imported[:tag_list]).to eq([])
    end
  end

  describe "scientific_domains" do
    context "when scientificDomains is absent" do
      it "builds an empty array" do
        expect(imported[:scientific_domains]).to eq([])
      end
    end

    context "when scientificDomains references known domains" do
      let!(:matching_domain) { create(:scientific_domain, eid: "scientific_domain-sd1") }
      let(:data) { { "scientificDomains" => ["scientific_domain-sd1"] } }

      it "resolves the matching ScientificDomain records" do
        expect(imported[:scientific_domains]).to contain_exactly(matching_domain)
      end
    end

    context "when scientificDomains contains nested subdomain hashes" do
      let!(:matching_domain) { create(:scientific_domain, eid: "scientific_domain-sub1") }

      let(:data) do
        {
          "scientificDomains" => [
            { "scientificDomain" => "scientific_domain-sd1" },
            { "scientificSubdomain" => "scientific_domain-sub1" }
          ]
        }
      end

      it "prefers the subdomain eid over the parent domain eid" do
        expect(imported[:scientific_domains]).to contain_exactly(matching_domain)
      end
    end
  end

  describe "public_contacts" do
    context "when publicContacts is absent" do
      it "builds an empty array" do
        expect(imported[:public_contacts]).to eq([])
      end
    end

    context "when publicContacts is an empty array" do
      let(:data) { { "publicContacts" => [] } }

      it "builds an empty array" do
        expect(imported[:public_contacts]).to eq([])
      end
    end

    context "when publicContacts is an array of plain emails" do
      let(:data) { { "publicContacts" => ["john@example.com"] } }

      it "builds a PublicContact for each email" do
        expect(imported[:public_contacts].map(&:email)).to contain_exactly("john@example.com")
      end
    end

    context "when publicContacts is an array of hashes" do
      let(:data) { { "publicContacts" => ["email" => "jane@example.com"] } }

      it "extracts the email from each hash" do
        expect(imported[:public_contacts].map(&:email)).to contain_exactly("jane@example.com")
      end
    end

    context "when publicContacts contains blank and duplicate emails" do
      let(:data) { { "publicContacts" => ["john@example.com", " ", "john@example.com"] } }

      it "drops blank entries and deduplicates" do
        expect(imported[:public_contacts].map(&:email)).to contain_exactly("john@example.com")
      end
    end
  end

  describe "main_contact" do
    context "when mainContact is absent" do
      it "is nil" do
        expect(imported[:main_contact]).to be_nil
      end
    end

    context "when mainContact is not a hash" do
      let(:data) { { "mainContact" => "not-a-hash" } }

      it "is nil" do
        expect(imported[:main_contact]).to be_nil
      end
    end

    context "when mainContact is a hash" do
      let(:data) do
        {
          "mainContact" => {
            "firstName" => "Jan",
            "lastName" => "Kowalski",
            "email" => "jan@example.com"
          }
        }
      end

      it "builds a MainContact" do
        expect(imported[:main_contact]).to be_a(MainContact)
      end

      it "maps known contact attributes" do
        expect(imported[:main_contact].attributes).to include(
          "first_name" => "Jan",
          "last_name" => "Kowalski",
          "email" => "jan@example.com"
        )
      end
    end

    context "when mainContact has fields with no matching Contact attribute" do
      let(:data) do
        {
          "mainContact" => {
            "firstName" => "Jan",
            "lastName" => "Kowalski",
            "email" => "jan@example.com",
            "role" => "PI",
            "affiliations" => ["x"]
          }
        }
      end

      it "ignores the unknown attributes" do
        expect(imported[:main_contact].attributes).to eq(
          MainContact.new(first_name: "Jan", last_name: "Kowalski", email: "jan@example.com").attributes
        )
      end
    end
  end
end
