# frozen_string_literal: true

require "rails_helper"

RSpec.describe Bundle::Unpublish::Cascading, :backend do
  let(:bundle) { create(:bundle, status: bundle_status) }

  before { described_class.call(bundle) }

  context "when the bundle is published" do
    let(:bundle_status) { :published }

    it "unpublishes the bundle" do
      expect(bundle.reload.status).to eq("unpublished")
    end
  end

  context "when the bundle is deleted" do
    let(:bundle_status) { :deleted }

    it "leaves the bundle deleted" do
      expect(bundle.reload.status).to eq("deleted")
    end
  end
end
