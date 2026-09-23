# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Services search", backend: true do
  it "returns the services list and reflects the submitted query" do
    get services_path(q: "Something")

    expect(response.status).to eq(200)
    expect(response.body).to include('value="Something"')
  end
end
