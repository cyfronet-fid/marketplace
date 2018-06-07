# frozen_string_literal: true

require "rails_helper"

RSpec.describe Category do
  it { should validate_presence_of(:name) }

  it "is hierarchical" do
    category = create(:category)
    subcategory = create(:category, parent: category)

    expect(subcategory.parent).to eq(category)
    expect(category.children).to include(subcategory)
  end
end
