# frozen_string_literal: true

require "rails_helper"

RSpec.describe Service::Destroy do
  it "removes service from db" do
    service = create(:service)

    described_class.new(service).call

    expect(Service.find_by(id: service.id)).to be_nil
  end
end
