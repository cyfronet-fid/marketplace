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

      create(:service, research_areas: [root], title: "Root service")
      create(:service, research_areas: [sub], title: "Sub service")
      create(:service, research_areas: [subsub], title: "Subsub service")
      create(:service, title: "Other service")

      visit services_path(research_areas: [root.id])
      expect(page).to have_text("Root service")
      expect(page).to have_text("Sub service")
      expect(page).to have_text("Subsub service")
      expect(page).to_not have_text("Other service")

      visit services_path(research_areas: [sub.id])
      expect(page).to_not have_text("Root service")
      expect(page).to have_text("Sub service")
      expect(page).to have_text("Subsub service")
      expect(page).to_not have_text("Other service")

      visit services_path(research_areas: [subsub.id])
      expect(page).to_not have_text("Root service")
      expect(page).to_not have_text("Sub service")
      expect(page).to have_text("Subsub service")
      expect(page).to_not have_text("Other service")
    end
  end

  context "filter search", js: true do
    it "shows only query result and selected" do
      a = create(:provider, name: "AAAA")
      c = create(:provider, name: "CCCC")
      z = create(:provider, name: "ZZZZ")

      visit services_path(providers: [c.id], "providers-filter": "AAA")

      expect(page).to have_text(a.name)
      expect(page).to have_text(c.name)
      expect(page).to_not have_text(z.name)
    end

    it "show query result, parent and selected" do
      parent_a = create(:research_area, name: "Z1")
      parent_c = create(:research_area, name: "Z2")
      parent_z = create(:research_area, name: "Z3")

      a = create(:research_area, parent: parent_a, name: "AAAA")
      c = create(:research_area, parent: parent_c, name: "CCCC")
      z = create(:research_area, parent: parent_z, name: "ZZZZ")

      visit services_path(research_areas: [c.id], "research_areas-filter": "AAA")

      expect(page).to have_text(a.name)
      expect(page).to have_text(parent_a.name)
      expect(page).to have_text(c.name)
      expect(page).to have_text(parent_c.name)
      expect(page).to_not have_text(z.name)
      expect(page).to_not have_text(parent_z.name)
    end
  end

  it "shows services with tag" do
    create(:service, tag_list: ["a"], title: "ATag")
    create(:service, tag_list: ["a", "b"], title: "ABTag")
    create(:service, tag_list: ["c"], title: "CTag")

    visit services_path(tag: "a")
    expect(page).to have_text("ATag")
    expect(page).to have_text("ABTag")
    expect(page).to_not have_text("CTag")

    visit services_path(tag: ["a", "b"])
    expect(page).to have_text("ATag")
    expect(page).to have_text("ABTag")
    expect(page).to_not have_text("CTag")

    visit services_path(tag: ["a", "b", "c"])
    expect(page).to have_text("ATag")
    expect(page).to have_text("ABTag")
    expect(page).to have_text("CTag")

    visit services_path(tag: ["d"])
    expect(page).to_not have_text("ATag")
    expect(page).to_not have_text("ABTag")
    expect(page).to_not have_text("CTag")
  end
end
