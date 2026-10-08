# frozen_string_literal: true

require "rails_helper"

RSpec.describe "catalogue api routes", type: :routing do
  before do
    allow(Mp::Variant).to receive(:pl?).and_return(pl)
    Rails.application.reload_routes!
  end

  after do
    allow(Mp::Variant).to receive(:pl?).and_call_original
    Rails.application.reload_routes!
  end

  context "when running as pl" do
    let(:pl) { true }

    it "routes the catalogue services api" do
      expect(get: "/api/v1/catalogue/services").to be_routable
    end
  end

  context "when running as another variant" do
    let(:pl) { false }

    it "does not route the catalogue services api" do
      expect(get: "/api/v1/catalogue/services").not_to be_routable
    end
  end
end
