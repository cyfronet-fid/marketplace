# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Comparison", js: true do
  let!(:service1) { create(:open_access_service, geographical_availabilities: %w( EL )) }
  let!(:service2) { create(:service, geographical_availabilities: %w( PL DE )) }
  let!(:service3) { create(:external_service, tag_list: %w( tag1 tag2 tag3 )) }

  it "doesn't show comparison bar until I click the Add to compare checkbox" do
    visit services_path

    expect(page).to_not have_selector("#comparison-bar")
  end

  it "shows comparison bar after click the Add to compare checkbox" do
    visit services_path

    find("#comparison-#{service1.id}", visible: false).click

    expect(page).to have_selector("#comparison-bar")
  end

  it "shows comparison bar on services view" do
    visit services_path

    find("#comparison-#{service1.id}", visible: false).click

    click_on "#{service1.name}", match: :first

    expect(page).to have_selector("#comparison-bar")
  end

  it "blocks other services checkboxes when 3 are checked" do
    service4 = create(:service)
    service5 = create(:service)

    visit services_path

    find("#comparison-#{service1.id}", visible: false).click
    find("#comparison-#{service2.id}", visible: false).click
    find("#comparison-#{service3.id}", visible: false).click

    expect(find_field("comparison-#{service4.id}", disabled: true, visible: false)).to be_present
    expect(find_field("comparison-#{service5.id}", disabled: true, visible: false)).to be_present
  end

  it "clears all elements when click on CLEAR ALL" do
    visit services_path

    checkbox1 = find("#comparison-#{service1.id}", visible: false).click
    checkbox2 = find("#comparison-#{service2.id}", visible: false).click
    checkbox3 = find("#comparison-#{service3.id}", visible: false).click

    click_on "Clear all"

    expect(checkbox1.checked?).to eql false
    expect(checkbox2.checked?).to eql false
    expect(checkbox3.checked?).to eql false
  end

  it "clears chosen element when click on trash icon" do
    visit services_path

    checkbox1 = find("#comparison-#{service1.id}", visible: false).click
    checkbox2 = find("#comparison-#{service2.id}", visible: false).click
    checkbox3 = find("#comparison-#{service3.id}", visible: false).click

    expect do
      find("a[value=#{service1.slug}").click
      expect(checkbox1.checked?).to eql false
      expect(checkbox2.checked?).to eql true
      expect(checkbox3.checked?).to eql true
    end
  end

  it "shows comparison page with correct data after click on compare" do
    visit services_path

    find("#comparison-#{service1.id}", visible: false).click
    find("#comparison-#{service2.id}", visible: false).click
    find("#comparison-#{service3.id}", visible: false).click

    click_on "Compare"

    expect(current_path).to eql comparisons_path

    expect(page).to have_content(service1.name)
    expect(page).to have_content(service2.name)
    expect(page).to have_content(service3.name)

    expect(page).to have_text("Providers")

    expect(page).to have_text(service1.providers.map(&:name).join(", "))
    expect(page).to have_text(service2.providers.map(&:name).join(", "))
    expect(page).to have_text(service3.providers.map(&:name).join(", "))

    expect(page).to have_text("Resource order type")

    expect(page).to have_text("Open Access")
    expect(page).to have_text("Order Required").twice

    expect(page).to have_text("Scientific domain")

    expect(page).to have_text(service1.scientific_domains.map(&:name).join(", "))
    expect(page).to have_text(service2.scientific_domains.map(&:name).join(", "))
    expect(page).to have_text(service3.scientific_domains.map(&:name).join(", "))

    expect(page).to have_text("Dedicated for")

    expect(page).to have_text(service1.target_users.map(&:name).join(", "))
    expect(page).to have_text(service2.target_users.map(&:name).join(", "))
    expect(page).to have_text(service3.target_users.map(&:name).join(", "))

    expect(page).to have_text("Resource life cycle status")

    expect(page).to have_text(service1.life_cycle_status.map(&:name).join(", "))
    expect(page).to have_text(service2.life_cycle_status.map(&:name).join(", "))
    expect(page).to have_text(service3.life_cycle_status.map(&:name).join(", "))

    expect(page).to have_text("Geographical availabilities")

    expect(page).to have_text("Greece")
    expect(page).to have_text("Poland, Germany")
    expect(page).to have_text("European Union")

    expect(page).to have_text("Languages")

    expect(page).to have_text(service1.languages.join(", "))
    expect(page).to have_text(service2.languages.join(", "))
    expect(page).to have_text(service3.languages.join(", "))

    expect(page).to have_text("Tags")

    expect(page).to have_selector("a[href='/services?tag=tag1']")
    expect(page).to have_selector("a[href='/services?tag=tag2']")
    expect(page).to have_selector("a[href='/services?tag=tag3']")
  end

  it "deletes service from comparison on comparison page" do
    @services = [service1, service2, service3]
    visit comparisons_path

    expect do
      find("a[value=#{service2.slug}]").click
      expect(current_path).to eql comparisons_path
      expect(page).to_not have_selector("a[value=#{service2.slug}]")
      expect(page).to have_selector("a[value=#{service1.slug}]")
      expect(page).to have_selector("a[value=#{service3.slug}]")
    end
  end

  it "redirects to services path when last service is deleted from comparison" do
    @services = [service1]
    visit comparisons_path

    expect do
      find("a[value=#{service2.slug}").click
      expect(current_path).to eql services_path
    end
  end
end
