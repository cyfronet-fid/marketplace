# frozen_string_literal: true

require "rails_helper"
require_relative "publishable"

RSpec.describe ScientificDomain, type: :model, backend: true do
  include_examples "publishable"

  describe "validations" do
    it { should validate_presence_of(:name) }

    subject { create(:scientific_domain) }
    it { should validate_uniqueness_of(:name).scoped_to(:ancestry) }
  end

  describe "#potential_parents" do
    it "includes potential parents" do
      scientific_domain = create(:scientific_domain)
      other = create(:scientific_domain)

      expect(scientific_domain.potential_parents).to eq([other])
    end

    it "returns all existing scientific domains for new record" do
      scientific_domain = ScientificDomain.new
      other = create(:scientific_domain)

      expect(scientific_domain.potential_parents).to eq([other])
    end

    it "does not include itself" do
      scientific_domain = create(:scientific_domain)

      expect(scientific_domain.potential_parents).to eq([])
    end

    it "does not include children" do
      scientific_domain = create(:scientific_domain)
      child = create(:scientific_domain, parent: scientific_domain)
      create(:scientific_domain, parent: child)

      expect(scientific_domain.potential_parents).to eq([])
    end
  end
end
