# frozen_string_literal: true

require "rails_helper"

RSpec.describe SearchLinksHelper, type: :helper do
  describe "#services_array_filter_link" do
    let(:search_base_url) { "https://search.example.com" }
    let(:guidelines) { [double(title: "Data & AI"), double(title: "Research/innovation?")] }

    before do
      allow(helper).to receive(:external_search_enabled).and_return(true)
      allow(Mp::Application.config).to receive(:search_service_base_url).and_return(search_base_url)
    end

    it "URL-encodes each guideline title in the external filter query" do
      expect(helper.services_array_filter_link(guidelines, :title)).to eq(
        "#{search_base_url}/search/service?q=*&fq=guidelines:" \
          "(%22Data%20%26%20AI%22 OR %22Research%2Finnovation%3F%22)"
      )
    end
  end
end
