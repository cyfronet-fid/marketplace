# frozen_string_literal: true

require "rails_helper"
require_relative "publishable"

RSpec.describe Category, :backend do
  include_examples "publishable"

  it { is_expected.to normalize(:eid).from(" ").to(nil) }

  describe "validations" do
    subject { create(:category) }

    it { is_expected.to validate_presence_of(:name) }

    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:ancestry) }
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
