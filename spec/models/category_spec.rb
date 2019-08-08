# frozen_string_literal: true

require "rails_helper"

RSpec.describe Category do
  describe "validations" do
    it { should validate_presence_of(:name) }

    subject { create(:category) }
    it { should validate_uniqueness_of(:name) }
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

  it "has services counter" do
    category = create(:category, services: create_list(:service, 1))
    subcategory = create(:category, parent: category, services: create_list(:service, 1))
    subsubcategory = create(:category, parent: subcategory, services: create_list(:service, 1))

    expect(subsubcategory.reload.services_count).to eq(1)
    expect(subcategory.reload.services_count).to eq(2)
    expect(category.reload.services_count).to eq(3)
  end
end
