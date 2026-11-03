# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Deployable services" do
  describe "GET /deployable_services/:id" do
    let(:deployable_service) { create(:deployable_service, creators: ["Creator One", "Creator Two"]) }

    before { get deployable_service_path(deployable_service) }

    it "renders the creators panel" do
      expect(response.body).to include("provider-panel")
    end

    it "renders the creator names" do
      expect(response.body).to include("Creator One", "Creator Two")
    end

    it "does not render the legacy creator fields" do
      expect(response.body).not_to include("Name type")
    end
  end
end
