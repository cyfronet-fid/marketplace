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
end
