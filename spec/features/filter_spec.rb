# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Service filtering" do
  include OmniauthHelper

  context "research area" do
    it "is hierarchical" do
      root = create(:research_area)
      sub = create(:research_area, parent: root)
      subsub = create(:research_area, parent: sub)

      visit services_path

      puts body
      expect(body).to have_text(root.name)
      # https://github.com/teamcapybara/capybara/issues/1440#issuecomment-62335948
      expect(body).to have_text("\u00a0\u00a0#{sub.name}")
      expect(body).to have_text("\u00a0\u00a0\u00a0\u00a0#{subsub.name}")
    end

    it "shows services from selected research area and sub research areas" do
      root = create(:research_area)
      sub = create(:research_area, parent: root)
      subsub = create(:research_area, parent: sub)

      create(:service, research_areas: [root])
      create(:service, research_areas: [sub])
      create(:service, research_areas: [subsub])
      create(:service)

      visit services_path(research_area: root.id)
      expect(page).to have_selector(".media", count: 3)

      visit services_path(research_area: sub.id)
      expect(page).to have_selector(".media", count: 2)

      visit services_path(research_area: subsub.id)
      expect(page).to have_selector(".media", count: 1)
    end
  end
end
