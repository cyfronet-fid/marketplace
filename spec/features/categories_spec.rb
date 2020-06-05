# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Service categories" do
  include OmniauthHelper

  let(:user) { create(:user) }

  before { checkin_sign_in_as(user) }

  scenario "service list shows root categories" do
    root1, root2 = create_list(:category, 2)
    sub_category = create(:category, parent: root1)

    visit services_path

    expect(page.body).to have_content root1.name
    expect(page.body).to have_content root2.name
    expect(page.body).to_not have_content sub_category.name
  end

  scenario "are hirearchical" do
    root = create(:category)
    sub_category1, sub_category2 = create_list(:category, 2, parent: root)
    sub_sub_category = create(:category, parent: sub_category1)

    visit category_path(root)

    expect(page.body).to have_content root.name

    expect(page.body).to have_content sub_category1.name
    expect(page.body).to have_content sub_category2.name
    expect(page.body).to_not have_content sub_sub_category.name
  end

  scenario "when in category siblings categories are shown" do
    root = create(:category)
    sub1, sub2 = create_list(:category, 2, parent: root)

    visit category_path(sub1)

    expect(body).to have_content sub1.name
    expect(body).to have_content sub2.name
  end

  scenario "shows services from category and subcategories" do
    root1, root2 = create_list(:category, 2)
    sub = create(:category, parent: root1)
    subsub = create(:category, parent: sub)

    s1 = create(:service, categories: [root1])
    s2 = create(:service, categories: [sub])
    s3 = create(:service, categories: [subsub])
    other_service = create(:service, categories: [root2])

    visit category_path(root1)

    expect(page.body).to have_content s1.name
    expect(page.body).to have_content s2.name
    expect(page.body).to have_content s3.name
    expect(page.body).to_not have_content other_service.name
  end

  scenario "limit number of services per page" do
    category = create(:category)
    create_list(:service, 2, categories: [category])

    visit category_services_path(category, per_page: "1")

    expect(page).to have_selector(".media", count: 1)
  end
end
