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

      expect(body).to have_text(root.name)
      expect(body).to have_text(sub.name)
      expect(body).to have_text(subsub.name)
    end

    it "shows services from selected research area and sub research areas" do
      root = create(:research_area)
      sub = create(:research_area, parent: root)
      subsub = create(:research_area, parent: sub)

      create(:service, research_areas: [root])
      create(:service, research_areas: [sub])
      create(:service, research_areas: [subsub])
      create(:service)

      visit services_path(research_areas: [root.id])
      expect(page).to have_selector(".media", count: 3)

      visit services_path(research_areas: [sub.id])
      expect(page).to have_selector(".media", count: 2)

      visit services_path(research_areas: [subsub.id])
      expect(page).to have_selector(".media", count: 1)
    end
  end

  it "shows services with tag" do
    create(:service, tag_list: ["a"])
    create(:service, tag_list: ["a", "b"])
    create(:service, tag_list: ["c"])

    visit services_path(tag: "a")
    expect(page).to have_selector(".media", count: 2)

    visit services_path(tag: ["a", "b"])
    expect(page).to have_selector(".media", count: 2)

    visit services_path(tag: ["a", "b", "c"])
    expect(page).to have_selector(".media", count: 3)

    visit services_path(tag: ["d"])
    expect(page).to have_selector(".media", count: 0)
  end
end
