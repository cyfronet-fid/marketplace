# frozen_string_literal: true

require "rails_helper"

RSpec.describe Category do
  describe "validations" do
    it { should validate_presence_of(:name) }

    subject { create(:category) }
    it { should validate_uniqueness_of(:name).scoped_to(:ancestry) }
  end

  it "is hierarchical" do
    category = create(:category)
    subcategory = create(:category, parent: category)

    expect(subcategory.parent).to eq(category)
    expect(category.children).to include(subcategory)
  end

  it "updates main service category when previous main is destroyed" do
    main, other = create_list(:category, 2)
    service = create(:service, categories: [main, other])

    main.destroy

    expect(service.main_category).to eq(other)
  end
end
