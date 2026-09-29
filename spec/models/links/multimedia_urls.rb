# frozen_string_literal: true

require "rails_helper"

RSpec.describe Link::MultimediaUrl, :backend, type: :model do
  let(:linkable) { Catalogue.new }

  it "is valid with link and without name" do
    expect(described_class.new(name: nil, url: "http://example.org", linkable: linkable)).to be_valid
  end

  it "is invalid with the link name without url" do
    expect(described_class.new(name: "Link", url: nil, linkable: linkable)).not_to be_valid
  end

  it "validates correct url" do
    expect(described_class.new(name: "Link", url: "example", linkable: linkable)).not_to be_valid
  end

  it "rejects URLs with a non-HTTP scheme" do
    expect(described_class.new(name: "Link", url: "javascript:alert(1)", linkable: linkable)).not_to be_valid
  end

  it "accepts HTTPS URLs" do
    expect(described_class.new(name: "Link", url: "https://example.org/video", linkable: linkable)).to be_valid
  end
end
