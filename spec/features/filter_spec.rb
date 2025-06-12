# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Service filter", end_user_frontend: true do
  include OmniauthHelper

  before do
    resources_selector = "body main div:nth-child(2).container div.container div.row div.col-lg-9"
    service_selector = "div.media.mb-3.service-box"
    @services_selector = resources_selector + " " + service_selector
  end

  context "wrapper" do
    it "can be opened", js: true do
      create(:provider, name: "Cyfronet provider")

      # By default all filters are expanded
      visit services_path
      expect(page).to_not have_text("Cyfronet provider")
      click_on "Providers"
      expect(page).to have_text("Cyfronet provider")
    end

    it "forgets a collapsable state", js: true do
      create(:scientific_domain, name: "Science!")

      visit services_path
      expect(page).to_not have_text("Science!")
      click_on "Scientific Domain"
      visit services_path
      expect(page).to_not have_text("Science!")
    end
  end

  it "respects search query" do
    visit services_path(q: "Funcy search phrase")
    expect(body).to have_text("Order type")
    find("#order_type-filter").click
    select "Other"

    expect(body).to have_text("Funcy search phrase")
  end

  it "stores filter state by breadcrumbs navigation" do
    scientific_domain = create(:scientific_domain, name: "Science!")
    provider = create(:provider, name: "Cyfronet provider")
    create(:service, name: "dd", providers: [provider], scientific_domains: [scientific_domain])

    visit services_path(q: "dd", providers: [provider.id], scientific_domains: [scientific_domain.id])
    find("a[href='/services/dd/offers']").click
    click_on "Services"

    expect(page).to have_text("Looking for: dd")
    expect(page).to have_text("Providers: Cyfronet provider")
  end

  it "reset page after filtering", js: true do
    create_list(:service, 5)

    visit services_path(page: 3, per_page: 1)
    find("#geographical_availabilities-filter").click
    select "European Union"

    expect(page.current_path).to_not have_content("page=")
  end

  it "allows to clear all filters" do
    cyfronet = create(:provider, name: "Cyfronet provider")
    create(:service, name: "Other service")
    create(:service, name: "Cyfronet service", providers: [cyfronet])

    visit services_path(providers: [cyfronet.id])

    all(@services_selector).each { |element| expect(element).to_not have_text("Other service") }

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
      all(@services_selector).each { |element| expect(element).to_not have_text("Other service") }

      visit services_path(scientific_domains: [sub.id])
      all(@services_selector).each { |element| expect(element).to_not have_text("Root service") }
      expect(page).to have_text("Sub service")
      expect(page).to have_text("Subsub service")
      all(@services_selector).each { |element| expect(element).to_not have_text("Other service") }

      visit services_path(scientific_domains: [subsub.id])
      all(@services_selector).each do |element|
        expect(element).to_not have_text("Root service")
        expect(element).to_not have_text("Sub service")
      end
      expect(page).to have_text("Subsub service")
      expect(page).to_not have_text("Other service")
      all(@services_selector).each { |element| expect(element).to_not have_text("Other service") }
    end

    it "shows first 5 elements by default", js: true do
      providers = create_list(:provider, 7)

      visit services_path

      click_on "Providers"

      expect(page).to have_text(providers[0].name)
      expect(page).to have_text(providers[4].name)
      expect(page).to_not have_text(providers[5].name)

      expect(page).to have_text("Show 2 more")
    end

    it "can show more/less elements", js: true do
      providers = create_list(:provider, 7)

      visit services_path

      click_on "Providers"

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

    it "respects query input on filter change", js: true do
      scientific_domains = create_list(:scientific_domain, 3)
      create(:service, name: "abc", scientific_domains: [scientific_domains[0]])

      visit services_path(q: "abc")

      click_on "Scientific Domains"

      find(:css, "input[name='scientific_domains[]'][value='#{scientific_domains[0].id}']", visible: false).set(true)

      expect(page).to have_current_path(services_path(q: "abc", scientific_domains: [scientific_domains[0].id]))
    end

    it "respect selected child", js: true do
      scientific_domains = create_list(:scientific_domain, 7)
      child = create(:scientific_domain, parent: scientific_domains[6])

      visit services_path(scientific_domains: [child.id])

      click_on "Providers"

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

    it "shows correct number of results in order type filter" do
      open_access_service = create(:open_access_service, offers: [create(:open_access_offer)])
      internal_ordering_service = create(:service, offers: [create(:offer)])
      external_service = create(:external_service, offers: [create(:external_offer)])
      mixed_offers_service = create(:service)
      create(:offer, service: mixed_offers_service)
      create(:open_access_offer, service: mixed_offers_service)
      Service.reindex
      visit services_path(order_type: :open_access)

      expect(page).to have_text(open_access_service.name)
      expect(page).to have_text(mixed_offers_service.name)
      all(@services_selector).each do |element|
        expect(element).to_not have_text(external_service.name)
        expect(element).to_not have_text(internal_ordering_service.name)
      end
    end
  end

  context "invisible filters" do
    it "shows services with tag" do
      create(:service, tag_list: ["a"], name: "ATag")
      create(:service, tag_list: %w[a b], name: "ABTag")
      create(:service, tag_list: ["c"], name: "CTag")

      visit services_path(tag: "a")
      expect(page).to have_text("ATag")
      expect(page).to have_text("ABTag")
      all(@services_selector).each { |element| expect(element).to_not have_text("CTag") }

      visit services_path(tag: %w[a b])
      expect(page).to have_text("ATag")
      expect(page).to have_text("ABTag")
      all(@services_selector).each { |element| expect(element).to_not have_text("CTag") }

      visit services_path(tag: %w[a b c])
      expect(page).to have_text("ATag")
      expect(page).to have_text("ABTag")
      expect(page).to have_text("CTag")

      visit services_path(tag: ["d"])
      all(@services_selector).each do |element|
        expect(element).to_not have_text("ATag")
        expect(element).to_not have_text("ABTag")
        expect(element).to_not have_text("CTag")
      end
    end
  end
end
