# frozen_string_literal: true

require "rails_helper"

RSpec.describe Presentable::ProviderInfoComponent, type: :component do
  subject(:rendered_component) { render_inline(described_class.new(base: base)) }

  let(:base) do
    double(resource_organisation: nil, creators: [{ "creatorName" => "Creator Name", "nameIdentifier" => creator_pid }])
  end

  context "with an HTTPS creator PID" do
    let(:creator_pid) { "https://orcid.org/0000-0001-2345-6789" }

    it "renders the PID as a safe external link" do
      rendered_component

      expect(page).to have_link(creator_pid, href: creator_pid)
      expect(page.find_link(creator_pid)[:target]).to eq("_blank")
      expect(page.find_link(creator_pid)[:rel]).to eq("noopener")
    end
  end

  context "with an unsafe creator PID" do
    let(:creator_pid) { "javascript:<script>alert('unsafe')</script>" }

    it "renders the escaped PID without a link" do
      rendered_component

      expect(page).to have_text(creator_pid)
      expect(page).to have_no_link(creator_pid)
      expect(page).to have_no_css("script")
      expect(page.native.to_html).to include("&lt;script&gt;")
    end
  end

  context "with a non-HTTPS creator PID" do
    let(:creator_pid) { "http://orcid.org/0000-0001-2345-6789" }

    it "renders the PID without a link" do
      rendered_component

      expect(page).to have_text(creator_pid)
      expect(page).to have_no_link(creator_pid)
    end
  end

  context "with nested creator metadata" do
    let(:creator_pid) { nil }
    let(:base) do
      double(
        resource_organisation: nil,
        creators: [
          {
            "creatorNameTypeInfo" => {
              "creatorName" => "Nested Creator Name"
            },
            "creatorName" => "Fallback Creator Name",
            "creatorAffiliationInfo" => {
              "affiliation" => "Creator Affiliation"
            }
          }
        ]
      )
    end

    it "preserves the name fallback order and affiliation" do
      rendered_component

      expect(page).to have_text("Nested Creator Name")
      expect(page).to have_text("Creator Affiliation")
      expect(page).to have_no_text("Fallback Creator Name")
    end
  end

  context "with a creator represented by a string" do
    let(:base) { double(resource_organisation: nil, creators: ["Creator Name"]) }

    it "renders the string as the creator name" do
      rendered_component

      expect(page).to have_text("Creator Name")
    end
  end
end
