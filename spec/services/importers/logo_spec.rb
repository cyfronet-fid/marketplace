# frozen_string_literal: true

require "rails_helper"

RSpec.describe Importers::Logo, backend: true do
  let(:url) { "https://example.com/PhenoMeNal_logo.png" }
  let(:image_double) { instance_double(Vips::Image, write_to_buffer: "converted-png-bytes") }

  before { allow(Vips::Image).to receive(:new_from_buffer).and_return(image_double) }

  describe "#call" do
    it "returns an attachable png for a valid png image" do
      stub_request(:get, url).to_return(body: "png-bytes", headers: { "Content-Type" => "image/png" })

      attachable = described_class.call(url)

      expect(Vips::Image).to have_received(:new_from_buffer).with("png-bytes", "")
      expect(attachable[:io]).to be_a(StringIO)
      expect(attachable[:filename]).to end_with(".png")
      expect(attachable[:content_type]).to eq("image/png")
context 'when image is valid' do
    before do
          stub_request(:get, url).to_return(body: "png-bytes", headers: { "Content-Type" => "image/png" })
    end
    
    let(:attachable) { described_class.call(url) }
    
    it "returns element of proper content type" do
      expect(attachable[:content_type]).to eq("image/png")
    end
    
    it 'calls Vips' do
          expect(Vips::Image).to have_received(:new_from_buffer).with("png-bytes", "")
    end
    
    it 'returns element of a class StringIO' do
          expect(attachable[:io]).to be_a(StringIO)
    end
    
    it 'file extention is png' do
      expect(attachable[:filename]).to end_with(".png")
    end
end


    it "renders svg images at a higher scale before converting to png" do
      stub_request(:get, url).to_return(body: "<svg></svg>", headers: { "Content-Type" => "image/svg+xml" })

      attachable = described_class.call(url)

      expect(Vips::Image).to have_received(:new_from_buffer).with("<svg></svg>", "scale=2")
      expect(attachable[:content_type]).to eq("image/png")
    end

    it "returns nil when the url is blank" do
      expect(described_class.call(nil)).to be_nil
    end

    it "returns nil when the response is not an image" do
      stub_request(:get, url).to_return(body: "<html></html>", headers: { "Content-Type" => "text/html" })

      expect(described_class.call(url)).to be_nil
    end

    it "returns nil when the response has no content type" do
      stub_request(:get, url).to_return(body: "png-bytes")

      expect(described_class.call(url)).to be_nil
    end

    it "returns nil on a 404 response" do
      stub_request(:get, url).to_return(status: 404)

      expect(described_class.call(url)).to be_nil
    end

    it "returns nil when the host is unreachable" do
      stub_request(:get, url).to_raise(Errno::EHOSTUNREACH)

      expect(described_class.call(url)).to be_nil
    end

    it "returns nil on a socket error" do
      stub_request(:get, url).to_raise(SocketError)

      expect(described_class.call(url)).to be_nil
    end

    it "returns nil when the download times out" do
      stub_request(:get, url).to_timeout

      expect(described_class.call(url)).to be_nil
    end
  end
end
