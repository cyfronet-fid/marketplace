# frozen_string_literal: true

require "rails_helper"

RSpec.describe Offer do
  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:description) }
  it { should validate_presence_of(:service) }

  it { should belong_to(:service) }

  it { should have_many(:project_items).dependent(:restrict_with_error) }

  context "#offer_type" do
    it "takes default from service if not set" do
      service = create(:catalog_service)
      offer = create(:offer, service: service)

      expect(offer.offer_type).to eq "catalog"
    end
  end

  context "#parameters" do
    it "should disallow null" do
      expect(build(:offer, parameters: nil).valid?).to be_falsey
    end

    it "should defaults to []" do
      expect(create(:offer).reload.parameters).to eq([])
    end
  end
end
