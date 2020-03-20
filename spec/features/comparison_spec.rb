# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Comparison", js: true do
  let!(:service1) { create(:service) }
  let!(:service2) { create(:service) }
  let!(:service3) { create(:service) }

  it "doesn't show comparison bar until I click the Add to compare checkbox" do
    visit services_path

    expect(page).to_not have_selector("#comparison-bar")
  end

  it "shows comparison bar after click the Add to compare checkbox" do
    visit services_path

    find("#comparison-#{service1.id}", visible: false).click

    expect(page).to have_selector("#comparison-bar")
  end

  it "blocks other services checkboxes when 3 are checked" do
    service4 = create(:service)
    service5 = create(:service)

    visit services_path

    find("#comparison-#{service1.id}", visible: false).click
    find("#comparison-#{service2.id}", visible: false).click
    find("#comparison-#{service3.id}", visible: false).click

    expect(find("#comparison-#{service4.id}", visible: false).disabled?).to eql true
    expect(find("#comparison-#{service5.id}", visible: false).disabled?).to eql true
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

  it "shows comparison page after click on compare" do
    visit services_path

    find("#comparison-#{service1.id}", visible: false).click
    find("#comparison-#{service2.id}", visible: false).click
    find("#comparison-#{service3.id}", visible: false).click

    click_on "Compare"

    expect(current_path).to eql comparisons_path
  end

  it "deletes service from comparison on comparison page" do
    @services = [service1, service2, service3]
    visit comparisons_path

    expect do
      find("a[value=#{service2.slug}").click
      expect(current_path).to eql comparisons_path
      expect(page).to_not have_selector("a[value=#{service2.slug}")
      expect(page).to have_selector("a[value=#{service1.slug}")
      expect(page).to have_selector("a[value=#{service3.slug}")
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
