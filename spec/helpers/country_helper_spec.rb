# frozen_string_literal: true

require "rails_helper"

RSpec.describe Country, type: :helper, backend: true do
  it "shengen area should contain only defined countries" do
    schengen_countries = Country.countries_for_region("Schengen Area")
    expect(schengen_countries.any?(&:nil?)).to be_falsey
  end
end
