# frozen_string_literal: true

require "rails_helper"

RSpec.describe "backoffice service unpublish route", type: :routing do
  before do
    allow(Mp::Variant).to receive(:whitelabel?).and_return(whitelabel)
    Rails.application.reload_routes!
  end

  after do
    allow(Mp::Variant).to receive(:whitelabel?).and_call_original
    Rails.application.reload_routes!
  end

  context "when running as whitelabel" do
    let(:whitelabel) { true }

    it "routes the service unpublish" do
      expect(post: "/backoffice/services/1/unpublish").to be_routable
    end
  end

  context "when running as another variant" do
    let(:whitelabel) { false }

    it "does not route the service unpublish" do
      expect(post: "/backoffice/services/1/unpublish").not_to be_routable
    end
  end
end
