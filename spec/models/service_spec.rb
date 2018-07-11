# frozen_string_literal: true

require "rails_helper"

RSpec.describe Service do
  it { should validate_presence_of(:title) }
  it { should validate_presence_of(:description) }
  it { should validate_presence_of(:tagline) }

  it { should belong_to(:owner) }

  it { should have_many(:service_categories).dependent(:destroy) }
  it { should have_many(:categories) }
  it { should have_many(:orders) }

  it "sets first category as default" do
    c1, c2 = create_list(:category, 2)
    service = create(:service, categories: [c1, c2])

    expect(service.service_categories.first.main).to be_truthy
    expect(service.service_categories.second.main).to be_falsy
  end

  it "allows to have only one main category" do
    c1, c2 = create_list(:category, 2)
    service = create(:service, categories: [c1])

    service.service_categories.create(category: c2, main: true)
    old_main = service.service_categories.find_by(category: c1)

    expect(old_main.main).to be_falsy
  end

  it "has main category" do
    main, other = create_list(:category, 2)
    service = create(:service, categories: [main, other])

    expect(service.main_category).to eq(main)
  end
end
