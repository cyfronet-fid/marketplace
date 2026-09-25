# frozen_string_literal: true

require "rails_helper"

RSpec.describe Link::MultimediaUrl, type: :model, backend: true do
  let(:linkable) { Catalogue.new }

  it "should be valid with link and without name" do
    expect(Link::MultimediaUrl.new(name: nil, url: "http://example.org", linkable: linkable)).to be_valid
  end

  it "should be invalid with the link name without url" do
    expect(Link::MultimediaUrl.new(name: "Link", url: nil, linkable: linkable)).not_to be_valid
  end

  it "should validate correct url" do
    expect(Link::MultimediaUrl.new(name: "Link", url: "example", linkable: linkable)).not_to be_valid
  end

  it "rejects URLs with a non-HTTP scheme" do
    expect(Link::MultimediaUrl.new(name: "Link", url: "javascript:alert(1)", linkable: linkable)).not_to be_valid
  end

  it "accepts HTTPS URLs" do
    expect(Link::MultimediaUrl.new(name: "Link", url: "https://example.org/video", linkable: linkable)).to be_valid
  end
end
