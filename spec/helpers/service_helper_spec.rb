# frozen_string_literal: true

require "rails_helper"

RSpec.describe ServiceHelper, :backend, type: :helper do
  it "converts from decimal 4.5 value to html" do
    expect(print_rating_stars(4.5)).to include('<i class="fas fa-star fa-lg"></i><i class="fas fa-star fa-lg"></i><i class="fas fa-star fa-lg"></i><i class="fas fa-star fa-lg"></i><i class="fas fa-star-half-alt fa-lg"></i>')
  end

  it "converts from decimal 5.0 value to html" do
    expect(print_rating_stars(5.0)).to include('<i class="fas fa-star fa-lg"></i><i class="fas fa-star fa-lg"></i><i class="fas fa-star fa-lg"></i><i class="fas fa-star fa-lg"></i><i class="fas fa-star fa-lg"></i>')
  end

  it "converts from decimal 0.0 value to html" do
    expect(print_rating_stars(0.0)).to include('<i class="fas fa-star empty-star fa-lg"></i><i class="fas fa-star empty-star fa-lg"></i><i class="fas fa-star empty-star fa-lg"></i><i class="fas fa-star empty-star fa-lg"></i><i class="fas fa-star empty-star fa-lg"></i>')
  end

  it "return list of providers" do
    list = create_list(:provider, 4)
    expect(providers_list.order(:created_at)).to eq(list)
  end

  describe "PL target users" do
    let(:target_user) { create(:target_user) }
    let(:service) { create(:service, target_users: [target_user]) }

    it "renders target-user data for the PL variant" do
      allow(Mp::Variant).to receive(:pl?).and_return(true)

      expect(dedicated_for_text(service)).to eq([target_user.name])
      expect(dedicated_for_links(service).first).to include(target_user.name)
    end

    it "keeps target-user data hidden for the V6 variants" do
      allow(Mp::Variant).to receive(:pl?).and_return(false)

      expect(dedicated_for_text(service)).to eq([])
      expect(dedicated_for_links(service)).to eq([])
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
