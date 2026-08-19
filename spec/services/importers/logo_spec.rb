# frozen_string_literal: true

require "rails_helper"

RSpec.describe Importers::Logo, backend: true do
  let(:service) { create(:service) }
  let(:provider) { create(:provider) }
  let(:url) { "http://phenomenal-h2020.eu/home/wp-content/uploads/2016/06/PhenoMeNal_logo.png" }

  before do
    stub_request(:get, url).to_return(
      status: 200,
      body: File.binread(file_fixture("PhenoMeNal_logo.png")),
      headers: { "Content-Type" => "image/png" }
    )
  end

  it "saves logo for service" do
    logo_importer = described_class.new(service, url)
    logo_importer.call

    expect(service.logo).to_not be_nil
  end

  it "saves logo for provider" do
    logo_importer = described_class.new(provider, url)
    logo_importer.call

    expect(service.logo).to_not be_nil
  end
end
