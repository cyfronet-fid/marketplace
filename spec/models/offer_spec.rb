# frozen_string_literal: true

require "rails_helper"

RSpec.describe Offer do
  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:description) }
  it { should validate_presence_of(:service) }
  it { should validate_presence_of(:order_type) }
  it { should belong_to(:service) }

  it { should have_many(:project_items).dependent(:restrict_with_error) }

  context "is open access" do
    subject { build(:offer, order_type: :open_access) }
    it { should validate_presence_of(:webpage) }
  end

  context "is external" do
    subject { build(:offer, order_type: :external) }
    it { should validate_presence_of(:webpage) }
  end

  context "is orderable" do
    subject { build(:offer, order_type: :orderable) }
    it { should_not validate_presence_of(:webpage) }
  end

  context "#parameters" do
    it "should defaults to []" do
      expect(create(:offer).reload.parameters).to eq([])
    end
  end
end
