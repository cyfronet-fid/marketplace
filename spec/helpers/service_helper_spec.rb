# frozen_string_literal: true

require "rails_helper"

RSpec.describe ServiceHelper, type: :helper do
  it "converts from decimal 4.5 value to html" do
    expect(print_rating_stars(4.5)).to match(/<i class="fas fa-star fa-lg"><\/i><i class="fas fa-star fa-lg"><\/i><i class="fas fa-star fa-lg"><\/i><i class="fas fa-star fa-lg"><\/i><i class="fas fa-star-half-alt fa-lg"><\/i>/)
  end

  it "converts from decimal 5.0 value to html" do
    expect(print_rating_stars(5.0)).to match(/<i class="fas fa-star fa-lg"><\/i><i class="fas fa-star fa-lg"><\/i><i class="fas fa-star fa-lg"><\/i><i class="fas fa-star fa-lg"><\/i><i class="fas fa-star fa-lg"><\/i>/)
  end

  it "converts from decimal 0.0 value to html" do
    expect(print_rating_stars(0.0)).to match(/<i class="far fa-star fa-lg"><\/i><i class="far fa-star fa-lg"><\/i><i class="far fa-star fa-lg"><\/i><i class="far fa-star fa-lg"><\/i><i class="far fa-star fa-lg"><\/i>/)
  end

  it "return list of providers" do
    list = create_list(:provider, 4)
    expect(get_providers_list.order(:created_at)).to eq(list)
  end

  context "#related_platforms" do
    it "for empty returns empty" do
      service = double(related_platforms: [])
      expect(related_platforms(service)).to eq([])
    end

    it "rejects entries which are empty after trim" do
      service = double(related_platforms: ["  ", "\t\n"])
      expect(related_platforms(service)).to eq([])
    end

    it "returns same if no highlights" do
      service = double(related_platforms: ["abc"])
      expect(related_platforms(service)).to eq(["abc"])
    end

    it "returns same if no matching highlights" do
      service = double(related_platforms: ["abc"])
      expect(related_platforms(service, { related_platforms: "<mark>ab</mark>" })).to eq(["abc"])
    end

    it "returns highlights if matching highlights" do
      service = double(related_platforms: ["abc", "bc"])
      expect(related_platforms(service, { related_platforms: "<mark>abc</mark>" })).to eq(["<mark>abc</mark>", "bc"])
    end

    it "returns highlights if matching highlights but stripping tags other than <mark>" do
      service = double(related_platforms: ["abc"])
      expect(related_platforms(service, { related_platforms: "<mark><strong>abc</strong></mark>" }))
        .to eq(["<mark>abc</mark>"])
    end
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
