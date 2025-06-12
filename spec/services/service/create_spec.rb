# frozen_string_literal: true

require "rails_helper"

RSpec.describe Service::Create, backend: true do
  let(:user) { create(:user) }

  it "saves valid service in db" do
    service = described_class.new(build(:service)).call

    expect(service).to be_persisted
  end

  it "doesn't save valid offer in the db" do
    service = described_class.new(build(:service)).call

    service.reload
    expect(service.offers.size).to eq(0)
  end
end
