# frozen_string_literal: true

require "rails_helper"

RSpec.describe Service::Create do
  let(:user) { create(:user) }

  it "saves valid service in db" do
    service = described_class.new(build(:service, owner: user)).call

    expect(service).to be_persisted
  end
end
