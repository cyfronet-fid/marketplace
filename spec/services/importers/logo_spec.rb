# frozen_string_literal: true

require "rails_helper"

RSpec.describe Importers::Logo, backend: true do
  let(:service) { create(:service) }
  let(:provider) { create(:provider) }

  def stub_http_file(logo_importer, file_fixture_name, url, content_type: "image/png")
    r = File.open(file_fixture(file_fixture_name))
    r.define_singleton_method(:content_type) { content_type }
    allow(logo_importer).to receive(:open).with(url, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE).and_return(r)
  end

  it "saves logo for service" do
    url = "http://phenomenal-h2020.eu/home/wp-content/uploads/2016/06/PhenoMeNal_logo.png"
    logo_importer = described_class.new(service, url)
    stub_http_file(logo_importer, "PhenoMeNal_logo.png", url)
    logo_importer.call

    expect(service.logo).to_not be_nil
  end

  it "saves logo for provider" do
    url = "http://phenomenal-h2020.eu/home/wp-content/uploads/2016/06/PhenoMeNal_logo.png"
    logo_importer = described_class.new(provider, url)
    stub_http_file(logo_importer, "PhenoMeNal_logo.png", url)
    logo_importer.call

    expect(service.logo).to_not be_nil
  end
end
