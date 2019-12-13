# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Executive stistics" do
  include OmniauthHelper

  before { checkin_sign_in_as(user) }

  context "as normal user" do
    let(:user) { create(:user) }

    scenario "I cannot see executive statistics" do
      visit executive_statistics_path

      expect(page.body).to have_no_selector("h1", text: "Statistics")
    end
  end

  context "as executive member" do
    let(:user) { create(:user, roles: [:executive]) }

    scenario "I can see executive statistics" do
      report = instance_double(UsageReport,
                               orderable_count: 1,
                               not_orderable_count: 2,
                               all_services_count: 3,
                               providers: ["p_a", "p_b", "p_c"],
                               disciplines: ["d_a", "d_b", "d_c", "d_d"],
                               countries: ["c_a", "c_b", "c_c", "c_d", "c_e"])
      allow(UsageReport).to receive(:new).and_return(report)

      visit executive_statistics_path

      expect(page.body).to have_selector("h1", text: "Statistics")
      expect(page.body).to have_text("1\nNumber of services orderable")
      expect(page.body).to have_text("2\nNumber of services not orderable")
      expect(page.body).to have_text("3\nAll services")
      expect(page.body).to have_text("Providers (3)")
      expect(page.body).to have_text("Disciplines (4)")
      expect(page.body).to have_text("Origins (5)")

      click_on "Providers (3)"
      expect(page.body).to have_text("p_a")
      expect(page.body).to have_text("p_b")
      expect(page.body).to have_text("p_c")

      click_on "Disciplines (4)"
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
