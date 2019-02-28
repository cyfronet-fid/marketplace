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
      service = create(:service, service_type: :catalog)
      offer = create(:offer, service: service)

      expect(offer.offer_type).to eq "catalog"
    end
  end

  context "bundle offer" do
    let(:source) { create(:offer) }
    let(:target) { create(:offer) }

    before { OfferLink.create!(source: source, target: target) }

    it "returns linked offer targets" do
      expect(source.bundled_offers).to contain_exactly(target)
    end

    it "remove link when source is removed" do
      expect { source.destroy! }.to change { OfferLink.count }.by(-1)
    end

    it "remove link when target is removed" do
      expect { target.destroy! }.to change { OfferLink.count }.by(-1)
    end

    it "is when there are linked offers" do
      expect(source).to be_bundle
      expect(target).to_not be_bundle
    end
  end
end
