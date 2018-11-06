# frozen_string_literal: true

require "rails_helper"

RSpec.describe Service do
  it { should validate_presence_of(:title) }
  it { should validate_presence_of(:description) }
  it { should validate_presence_of(:tagline) }
  it { should validate_presence_of(:provider) }
  it { should validate_presence_of(:rating) }

  it { should validate_presence_of(:places) }
  it { should validate_presence_of(:languages) }
  it { should validate_presence_of(:dedicated_for) }
  it { should validate_presence_of(:terms_of_use_url) }
  it { should validate_presence_of(:access_policies_url) }
  it { should validate_presence_of(:corporate_sla_url) }
  it { should validate_presence_of(:webpage_url) }
  it { should validate_presence_of(:manual_url) }
  it { should validate_presence_of(:helpdesk_url) }
  it { should validate_presence_of(:tutorial_url) }
  it { should validate_presence_of(:restrictions) }
  it { should validate_presence_of(:phase) }

  it { should belong_to(:owner) }
  it { should belong_to(:provider) }

  it { should have_many(:service_categories).dependent(:destroy) }
  it { should have_many(:offers).dependent(:restrict_with_error) }
  it { should have_many(:categories) }
  it { should have_many(:service_research_areas).dependent(:destroy) }

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

  context "if open access" do
    before { allow(subject).to receive(:open_access?) { true } }

    it { is_expected.to validate_presence_of(:connected_url) }
  end

  context "if not open access" do
    before { allow(subject).to receive(:open_access?) { false } }

    it { is_expected.to_not validate_presence_of(:connected_url) }
  end

  it "has rating" do
    expect(create(:service).rating).to eq(0.0)
  end

  it "has related services" do
    s1, s2, s3 = create_list(:service, 3)

    ServiceRelationship.create(source: s1, target: s2)
    ServiceRelationship.create(source: s1, target: s3)

    expect(s1.related_services).to contain_exactly(s2, s3)
  end
end
