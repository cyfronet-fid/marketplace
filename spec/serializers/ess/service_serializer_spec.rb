# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ess::ServiceSerializer, backend: true do
  around do |example|
    default_host = Rails.application.routes.default_url_options[:host]
    example.run
  ensure
    Rails.application.routes.default_url_options[:host] = default_host
  end

  it "serializes an attached logo without requiring a configured URL host" do
    service = create(:service)
    service.logo.attach(
      io: File.open(Rails.root.join("spec/fixtures/files/PhenoMeNal_logo.png")),
      filename: "PhenoMeNal_logo.png",
      content_type: "image/png"
    )
    Rails.application.routes.default_url_options[:host] = nil

    data = described_class.new(service).as_json

    expect(data[:logo]).to eq("/services/#{service.slug}/logo")
  end
end
