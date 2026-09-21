# frozen_string_literal: true

require "rails_helper"

RSpec.describe Importable do
  subject(:importer) { Class.new { include Importable }.new }

  describe "#map_link" do
    it "maps HTTP and HTTPS multimedia URLs" do
      expect(importer.map_link("https://example.org/video")).to have_attributes(
        name: "",
        url: "https://example.org/video"
      )
    end

    it "maps a hash containing a valid multimedia URL" do
      expect(
        importer.map_link("multimediaName" => "Video", "multimediaURL" => "http://example.org/video")
      ).to have_attributes(name: "Video", url: "http://example.org/video")
    end

    it "rejects a hash containing a non-HTTP multimedia URL" do
      expect(importer.map_link("multimediaName" => "Video", "multimediaURL" => "javascript:alert(1)")).to be_nil
    end
  end
end
