# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Help" do
  scenario "I can see generated help page", end_user_frontend: true do
    section = create(:help_section)
    item = create(:help_item, help_section: section, content: "Help item content")

    visit help_path

    expect(page).to have_content(section.title)
    expect(page).to have_content(item.title)
    click_on item.title
    expect(page).to have_content("Help item content")
  end

  scenario "sections are sorted using postion field" do
    second_section = create(:help_section, position: 2)
    third_section = create(:help_section, position: 3)
    first_section = create(:help_section, position: 1)

    visit help_path

    expect(page.body.index(first_section.title)).to be < page.body.index(second_section.title)
    expect(page.body.index(second_section.title)).to be < page.body.index(third_section.title)
  end

  scenario "section items are sorted using postion field" do
    section = create(:help_section)

    second_item = create(:help_item, help_section: section, position: 2)
    third_item = create(:help_item, help_section: section, position: 3)
    first_item = create(:help_item, help_section: section, position: 1)

    visit help_path

    expect(page.body.index(first_item.title)).to be < page.body.index(second_item.title)
    expect(page.body.index(second_item.title)).to be < page.body.index(third_item.title)
  end
end
