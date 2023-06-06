# frozen_string_literal: true

require "rails_helper"

RSpec.describe Link::MultimediaUrl, type: :model, backend: true do
  it "should be valid with link and without name" do
    Link::MultimediaUrl.new(name: nil, url: "http://example.org").should be_valid
  end

  it "should be invalid with the link name without url" do
    Link::MultimediaUrl.new(name: "Link", url: nil).should_not be_valid
  end

  it "should validate correct url" do
    Link::MultimediaUrl.new(name: "Link", url: "example").should_not be_valid
  end
end
