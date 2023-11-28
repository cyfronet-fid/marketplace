# frozen_string_literal: true

require "rails_helper"

RSpec.describe ServiceHelper, type: :helper, backend: true do
  it "converts from decimal 4.5 value to html" do
    expect(print_rating_stars(4.5)).to match(
      %r{<i class="fas fa-star fa-lg"></i><i class="fas fa-star fa-lg"></i><i class="fas fa-star fa-lg"></i><i class="fas fa-star fa-lg"></i><i class="fas fa-star-half-alt fa-lg"></i>}
    )
  end

  it "converts from decimal 5.0 value to html" do
    expect(print_rating_stars(5.0)).to match(
      %r{<i class="fas fa-star fa-lg"></i><i class="fas fa-star fa-lg"></i><i class="fas fa-star fa-lg"></i><i class="fas fa-star fa-lg"></i><i class="fas fa-star fa-lg"></i>}
    )
  end

  it "converts from decimal 0.0 value to html" do
    expect(print_rating_stars(0.0)).to match(
      %r{<i class="fas fa-star empty-star fa-lg"></i><i class="fas fa-star empty-star fa-lg"></i><i class="fas fa-star empty-star fa-lg"></i><i class="fas fa-star empty-star fa-lg"></i><i class="fas fa-star empty-star fa-lg"></i>}
    )
  end

  it "return list of providers" do
    list = create_list(:provider, 4)
    expect(providers_list.order(:created_at)).to eq(list)
  end

  it "return trl description" do
    service = create(:service)
    expect(trl_description_text(service)).to eq("Super description")
  end

  it "return only regions from geographical_availabilities" do
    poland = Country.load("PL")
    europe = Country.load("EO")
    expect(get_only_regions([poland, europe])).to eq([europe])
  end

  it "return only countries from geographical_availabilities" do
    poland = Country.load("PL")
    europe = Country.load("EO")
    expect(get_only_countries([poland, europe])).to eq([poland])
  end
end
