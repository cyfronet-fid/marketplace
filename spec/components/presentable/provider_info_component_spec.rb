# frozen_string_literal: true

require "rails_helper"

RSpec.describe Presentable::ProviderInfoComponent, type: :component do
  subject(:rendered_component) { render_inline(described_class.new(base: base)) }

  let(:base) do
    double(resource_organisation: nil, creators: ["creatorName" => "Creator Name", "nameIdentifier" => creator_pid])
  end

  context "with an HTTPS creator PID" do
    let(:creator_pid) { "https://orcid.org/0000-0001-2345-6789" }

    it "renders the PID as a safe external link" do
      rendered_component

      expect(page).to have_css(
        "a[href='#{creator_pid}'][target='_blank'][rel='noopener']",
        text: creator_pid
      )
    end
  end

  context "with an unsafe creator PID" do
    let(:creator_pid) { "javascript:<script>alert('unsafe')</script>" }

    it "renders the PID as text" do
      rendered_component

      expect(page).to have_text(creator_pid)
    end

    it "does not render a link" do
      rendered_component

      expect(page).to have_no_link(creator_pid)
    end

    it "does not render script markup" do
      rendered_component

      expect(page).to have_no_css("script")
    end

    it "escapes the script markup" do
      rendered_component

      expect(page.native.to_html).to include("&lt;script&gt;")
    end
  end

  context "with a non-HTTPS creator PID" do
    let(:creator_pid) { "http://orcid.org/0000-0001-2345-6789" }

    it "renders the PID as text" do
      rendered_component

      expect(page).to have_text(creator_pid)
    end

    it "does not render a link" do
      rendered_component

      expect(page).to have_no_link(creator_pid)
    end
  end

  context "with nested creator metadata" do
    let(:creator_pid) { nil }
    let(:base) do
      double(
        resource_organisation: nil,
        creators: [
          "creatorNameTypeInfo" => {
            "creatorName" => "Nested Creator Name"
          },
          "creatorName" => "Fallback Creator Name",
          "creatorAffiliationInfo" => {
            "affiliation" => "Creator Affiliation"
          }
        ]
      )
    end

    it "uses the nested creator name before the fallback name" do
      rendered_component

      expect(page).to have_text("Nested Creator Name")
    end

    it "renders the creator affiliation" do
      rendered_component

      expect(page).to have_text("Creator Affiliation")
    end

    it "does not render the fallback creator name" do
      rendered_component

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
