# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Service filter" do
  include OmniauthHelper

  context "wrapper" do
    it "can be closed", js: true do
      create(:provider, name: "Cyfronet provider")

      # By default all filters are expanded
      visit services_path
      expect(page).to have_text("Cyfronet provider")
      click_on "Providers"
      expect(page).to_not have_text("Cyfronet provider")
    end

    it "stores collapsable state", js: true do
      create(:scientific_domain, name: "Science!")

      visit services_path
      expect(page).to have_text("Science!")
      click_on "Scientific Domain"
      visit services_path
      expect(page).to_not have_text("Science!")
    end
  end

  it "respects seach query", js: true do
    visit services_path(q: "Funcy search phrase")
    select "EU"

    expect(body).to have_text("Funcy search phrase")
  end

  it "stores filter state by breadcrumbs navigation", js: true do
    scientific_domain = create(:scientific_domain, name: "Science!")
    provider = create(:provider, name: "Cyfronet provider")
    create(:service, name: "dd", providers: [provider], scientific_domains: [scientific_domain])

    visit services_path(q: "dd", providers: [provider.to_param], scientific_domains: [scientific_domain.to_param])
    click_on "dd"
    click_on "Services"

    expect(page).to have_text("Looking for: dd")
    expect(page).to have_text("Providers: Cyfronet provider")
  end

  it "reset page after filtering", js: true do
    create_list(:service, 5)

    visit services_path(page: 3, per_page: 1)
    select "EU"

    expect(page.current_path).to_not have_content("page=")
  end

  it "allows to clear all filters" do
    cyfronet = create(:provider, name: "Cyfronet provider")
    create(:service, name: "Other service")
    create(:service, name: "Cyfronet service", providers: [cyfronet])

    visit services_path(providers: [cyfronet.to_param])
    expect(page).to_not have_text("Other service")

    click_on "Clear all filters"

    expect(page).to have_text("Other service")
  end

  it "shows active filters" do
    platform = create(:platform)

    visit services_path(related_platforms: [platform.id])
    expect(page).to have_selector(".active-filters > *", count: 2)
  end

  context "multicheckbox" do
    it "can be hierarchical" do
      root = create(:scientific_domain)
      sub = create(:scientific_domain, parent: root)
      subsub = create(:scientific_domain, parent: sub)

      visit services_path

      expect(body).to have_text(root.name)
      expect(body).to have_text(sub.name)
      expect(body).to have_text(subsub.name)
    end

    it "show services from root and children when hierarchical" do
      root = create(:scientific_domain)
      sub = create(:scientific_domain, parent: root)
      subsub = create(:scientific_domain, parent: sub)

      create(:service, scientific_domains: [root], name: "Root service")
      create(:service, scientific_domains: [sub], name: "Sub service")
      create(:service, scientific_domains: [subsub], name: "Subsub service")
      create(:service, name: "Other service")

      visit services_path(scientific_domains: [root.id])
      expect(page).to have_text("Root service")
      expect(page).to have_text("Sub service")
      expect(page).to have_text("Subsub service")
      expect(page).to_not have_text("Other service")

      visit services_path(scientific_domains: [sub.id])
      expect(page).to_not have_text("Root service")
      expect(page).to have_text("Sub service")
      expect(page).to have_text("Subsub service")
      expect(page).to_not have_text("Other service")

      visit services_path(scientific_domains: [subsub.id])
      expect(page).to_not have_text("Root service")
      expect(page).to_not have_text("Sub service")
      expect(page).to have_text("Subsub service")
      expect(page).to_not have_text("Other service")
    end

    it "shows first 5 elements by default", js: true do
      providers = create_list(:provider, 7)

      visit services_path

      expect(page).to have_text(providers[0].name)
      expect(page).to have_text(providers[4].name)
      expect(page).to_not have_text(providers[5].name)

      expect(page).to have_text("Show 2 more")
    end

    it "can show more/less elements", js: true do
      providers = create_list(:provider, 7)

      visit services_path
      click_on "Show 2 more"

      expect(page).to have_text(providers[5].name)
      expect(page).to have_text(providers[6].name)

      click_on "Show less"
      expect(page).to_not have_text(providers[5].name)
      expect(page).to_not have_text(providers[6].name)
    end

    it "respect selected elements", js: true do
      providers = create_list(:provider, 7)

      visit services_path(providers: [providers[6].id])

      expect(page).to_not have_text(providers[5].name)
      expect(page).to have_text(providers[6].name)
      expect(page).to have_text("Show 1 more")
    end

    it "respect selected child", js: true do
      scientific_domains = create_list(:scientific_domain, 7)
      child = create(:scientific_domain, parent: scientific_domains[6])

      visit services_path(scientific_domains: [child.id])

      expect(page).to_not have_text(scientific_domains[5].name)
      expect(page).to have_text(scientific_domains[6].name)
      expect(page).to have_text(child.name)
      expect(page).to have_text("Show 1 more")
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
      parent_a = create(:scientific_domain, name: "Z1")
      parent_c = create(:scientific_domain, name: "Z2")
      parent_z = create(:scientific_domain, name: "Z3")

      a = create(:scientific_domain, parent: parent_a, name: "AAAA")
      c = create(:scientific_domain, parent: parent_c, name: "CCCC")
      z = create(:scientific_domain, parent: parent_z, name: "ZZZZ")

      visit services_path(scientific_domains: [c.id], "scientific_domains-filter": "AAA")

      expect(page).to have_text(a.name)
      expect(page).to have_text(parent_a.name)
      expect(page).to have_text(c.name)
      expect(page).to have_text(parent_c.name)
      expect(page).to_not have_text(z.name)
      expect(page).to_not have_text(parent_z.name)
    end
  end

  context "invisible filters" do
    it "shows services with tag" do
      create(:service, tag_list: ["a"], name: "ATag")
      create(:service, tag_list: ["a", "b"], name: "ABTag")
      create(:service, tag_list: ["c"], name: "CTag")

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
end
