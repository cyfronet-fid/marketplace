# frozen_string_literal: true

require "rails_helper"

RSpec.describe Service::Update do
  it "updates attributes" do
    service = create(:service)

    described_class.new(service, title: "new title").call

    expect(service.title).to eq("new title")
  end
end
