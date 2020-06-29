# frozen_string_literal: true

require "rails_helper"

RSpec.describe Service::Update do
  it "updates attributes" do
    service = create(:service)

    described_class.new(service, name: "new name").call

    expect(service.name).to eq("new name")
  end
end
