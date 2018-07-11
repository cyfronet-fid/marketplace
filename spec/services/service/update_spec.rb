# frozen_string_literal: true

require "rails_helper"

RSpec.describe Service::Update do
  let(:user) { create(:user) }
  let(:service) { create(:service, owner: user) }

  it "updates affiliation" do
    described_class.new(service, title: "new title").call

    expect(service.title).to eq("new title")
  end
end
