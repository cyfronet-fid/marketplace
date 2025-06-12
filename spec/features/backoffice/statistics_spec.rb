# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Executive stistics", manager_frontend: true do
  include OmniauthHelper

  before { checkin_sign_in_as(user) }

  context "as normal user" do
    let(:user) { create(:user) }

    scenario "I cannot see executive statistics" do
      visit backoffice_statistics_path

      expect(page.body).to have_no_selector("h1", text: "Statistics")
    end
  end

  context "as coordinator" do
    let(:user) { create(:user, roles: [:coordinator]) }

    scenario "I can see executive statistics" do
      report =
        instance_double(
          UsageReport,
          orderable_count: 1,
          not_orderable_count: 2,
          all_services_count: 3,
          order_required_count: 1,
          fully_open_access_count: 0,
          open_access_count: 1,
          other_count: 1,
          providers: %w[p_a p_b p_c],
          domains: %w[d_a d_b d_c d_d],
          countries: %w[c_a c_b c_c c_d c_e]
        )
      allow(UsageReport).to receive(:new).and_return(report)

      visit backoffice_statistics_path

      expect(page.body).to have_selector("h1", text: "Statistics")
      expect(page.body).to have_text(
        "1\nNumber of EOSC services with offerings using EOSC Marketplace ordering process"
      )
      expect(page.body).to have_text("2\nNumber of EOSC services not using EOSC Marketplace ordering process")
      expect(page.body).to have_text("3\nNumber of all EOSC services registered in the EOSC Marketplace")
      expect(page.body).to have_text("0\nNumber of services with at least one fully open access offer")
      expect(page.body).to have_text("1\nNumber of services with at least one open access offer")
      expect(page.body).to have_text("1\nNumber of services with at least one offer requiring ordering")
      expect(page.body).to have_text("1\nNumber of services with at least one other offer.")

      expect(page.body).to have_text("Providers (3)")
      expect(page.body).to have_text("Domains (4)")
      expect(page.body).to have_text("Origins (5)")

      click_on "Providers (3)"
      expect(page.body).to have_text("p_a")
      expect(page.body).to have_text("p_b")
      expect(page.body).to have_text("p_c")

      click_on "Domains (4)"
      expect(page.body).to have_text("d_a")
      expect(page.body).to have_text("d_b")
      expect(page.body).to have_text("d_c")
      expect(page.body).to have_text("d_c")

      click_on "Origins (5)"
      expect(page.body).to have_text("c_a")
      expect(page.body).to have_text("c_b")
      expect(page.body).to have_text("c_c")
      expect(page.body).to have_text("c_d")
      expect(page.body).to have_text("c_e")
    end
  end
end
