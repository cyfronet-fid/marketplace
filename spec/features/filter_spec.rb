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
      create(:research_area, name: "Science!")

      visit services_path
      expect(page).to have_text("Science!")
      click_on "Research Area"
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
    research_area = create(:research_area, name: "Science!")
    provider = create(:provider, name: "Cyfronet provider")
    create(:service, title: "dd", providers: [provider], research_areas: [research_area])

    visit services_path(q: "dd", providers: [provider.to_param], research_areas: [research_area.to_param])
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
    create(:service, title: "Other service")
    create(:service, title: "Cyfronet service", providers: [cyfronet])

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
      root = create(:research_area)
      sub = create(:research_area, parent: root)
      subsub = create(:research_area, parent: sub)

      visit services_path

      expect(body).to have_text(root.name)
      expect(body).to have_text(sub.name)
      expect(body).to have_text(subsub.name)
    end

    it "show services from root and children when hierarchical" do
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
      research_areas = create_list(:research_area, 7)
      child = create(:research_area, parent: research_areas[6])

      visit services_path(research_areas: [child.id])

      expect(page).to_not have_text(research_areas[5].name)
      expect(page).to have_text(research_areas[6].name)
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

    it "shows correct number of results in order type filter" do
      open_access_service = create(:open_access_service, offers: [create(:open_access_offer)])
      internal_ordering_service = create(:service, offers: [create(:offer)])
      external_service = create(:external_service, offers: [create(:external_offer)])
      mixed_offers_services = create(:service, offers: [create(:open_access_offer, iid: 1),
                                                               create(:offer, iid: 2)])
      visit services_path(service_type: "open_access")
      expect(page).to have_text(open_access_service.title)
      expect(page).to have_text(mixed_offers_services.title)
      expect(page).to_not have_text(external_service.title)
      expect(page).to_not have_text(internal_ordering_service.title)
    end
  end

  context "invisible filters" do
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
end
