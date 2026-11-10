# frozen_string_literal: true

require "rails_helper"

RSpec.describe "deployable services routes", type: :routing do
  before do
    allow(Mp::Variant).to receive(:marketplace?).and_return(marketplace)
    Rails.application.reload_routes!
  end

  after do
    allow(Mp::Variant).to receive(:marketplace?).and_call_original
    Rails.application.reload_routes!
  end

  context "when running as marketplace" do
    let(:marketplace) { true }

    it "routes the public deployable services pages" do
      expect(get: "/deployable_services").to be_routable
    end

    it "routes the infrastructure removal" do
      expect(delete: "/projects/1/services/2/infrastructure").to be_routable
    end

    it "routes the ESS deployable services api" do
      expect(get: "/api/v1/ess/deployable_services").to be_routable
    end
  end

  context "when running as another variant" do
    let(:marketplace) { false }

    it "does not route the public deployable services pages" do
      expect(get: "/deployable_services").not_to be_routable
    end

    it "does not route the infrastructure removal" do
      expect(delete: "/projects/1/services/2/infrastructure").not_to be_routable
    end

    it "does not route the ESS deployable services api" do
      expect(get: "/api/v1/ess/deployable_services").not_to be_routable
    end
  end
end
