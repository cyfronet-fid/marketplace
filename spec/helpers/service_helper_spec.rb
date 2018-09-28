# frozen_string_literal: true

require "rails_helper"

RSpec.describe ServiceHelper, type: :helper do
  it "converts from decimal 4.5 value to html" do
    expect(print_rating_stars(4.5)).to match(/<i class="fas fa-star"><\/i><i class="fas fa-star"><\/i><i class="fas fa-star"><\/i><i class="fas fa-star"><\/i><i class="fas fa-star-half-alt"><\/i>/)
  end

  it "converts from decimal 5.0 value to html" do
    expect(print_rating_stars(5.0)).to match(/<i class="fas fa-star"><\/i><i class="fas fa-star"><\/i><i class="fas fa-star"><\/i><i class="fas fa-star"><\/i><i class="fas fa-star"><\/i>/)
  end

  it "converts from decimal 0.0 value to html" do
    expect(print_rating_stars(0.0)).to match(/<i class="far fa-star"><\/i><i class="far fa-star"><\/i><i class="far fa-star"><\/i><i class="far fa-star"><\/i><i class="far fa-star"><\/i>/)
  end

  it "return list of providers" do
    list = create_list(:provider, 4)
    expect(get_providers_list).to eq(list)
  end
end
