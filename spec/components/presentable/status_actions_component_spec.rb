# frozen_string_literal: true

require "rails_helper"

RSpec.describe Presentable::StatusActionsComponent, type: :component do
  let(:service) { create(:service) }
  let(:component) { described_class.new(object: service, publish: true, unpublish: true, suspend: true) }
  let(:routes) { Rails.application.routes.url_helpers }

  context "when running as marketplace" do
    subject(:html) { render_inline(component).to_html }

    it "renders the marketplace layout" do
      expect(html).to include("status-column")
    end

    it "unpublishes services through drafts" do
      expect(html).to include(routes.backoffice_service_draft_path(service))
    end
  end

  context "when running as pl" do
    subject(:html) { with_variant(:pl) { render_inline(component).to_html } }

    it "renders the pl layout" do
      expect(html).to include("status-row")
    end

    it "unpublishes services through drafts" do
      expect(html).to include(routes.backoffice_service_draft_path(service))
    end
  end

  context "when running as whitelabel" do
    subject(:html) { with_variant(:whitelabel) { render_inline(component).to_html } }

    before do
      allow(Mp::Variant).to receive_messages(marketplace?: false, pl?: false, whitelabel?: true)
      Rails.application.reload_routes!
    end

    after do
      allow(Mp::Variant).to receive(:marketplace?).and_call_original
      allow(Mp::Variant).to receive(:pl?).and_call_original
      allow(Mp::Variant).to receive(:whitelabel?).and_call_original
      Rails.application.reload_routes!
    end

    it "renders the whitelabel layout in a turbo frame" do
      expect(html).to include('id="status_management"')
    end

    it "unpublishes services through the unpublish resource" do
      expect(html).to include(routes.backoffice_service_unpublish_path(service))
    end
  end
end
