# frozen_string_literal: true

require "rails_helper"

RSpec.describe Importers::Logo, :backend do
  subject(:attachable) { described_class.call(url) }

  let(:url) { "https://example.com/PhenoMeNal_logo.png" }
  let(:image_double) { instance_double(Vips::Image, write_to_buffer: "converted-png-bytes") }

  before { allow(Vips::Image).to receive(:new_from_buffer).and_return(image_double) }

  describe "#call" do
    context "when image is valid" do
      before do
        stub_request(:get, url).to_return(body: "png-bytes", headers: { "Content-Type" => "image/png" })
      end

      it "returns element of proper content type" do
        expect(attachable[:content_type]).to eq("image/png")
      end

      it "calls Vips" do
        attachable

        expect(Vips::Image).to have_received(:new_from_buffer).with("png-bytes", "")
      end

      it "returns element of a class StringIO" do
        expect(attachable[:io]).to be_a(StringIO)
      end

      it "file extention is png" do
        expect(attachable[:filename]).to end_with(".png")
      end
    end

    context "when image is svg" do
      before do
        stub_request(:get, url).to_return(body: "<svg></svg>", headers: { "Content-Type" => "image/svg+xml" })
      end

      it "returns element of proper content type" do
        expect(attachable[:content_type]).to eq("image/png")
      end

      it "calls Vips with scale=2" do
        attachable

        expect(Vips::Image).to have_received(:new_from_buffer).with("<svg></svg>", "scale=2")
      end
    end

    context "when url is blank" do
      let(:url) { "" }

      it "returns nil" do
        expect(attachable).to be_nil
      end
    end

    context "when url is nil" do
      let(:url) { nil }

      it "returns nil" do
        expect(attachable).to be_nil
      end
    end

    context "when url is invalid" do
      let(:url) { "https://example.com/ logo.png" }

      it "returns nil" do
        expect(attachable).to be_nil
      end
    end

    context "when url is unreachable" do
      before do
        stub_request(:get, url).to_raise(Errno::EHOSTUNREACH)
      end

      it "returns nil" do
        expect(attachable).to be_nil
      end
    end

    context "when url does not point to an image" do
      before do
        stub_request(:get, url).to_return(body: "<html></html>", headers: { "Content-Type" => "text/html" })
      end

      it "returns nil" do
        expect(attachable).to be_nil
      end
    end

    context "when response has no content type" do
      before do
        stub_request(:get, url).to_return(body: "png-bytes")
      end

      it "returns nil" do
        expect(attachable).to be_nil
      end
    end

    context "when response status is 404" do
      before do
        stub_request(:get, url).to_return(status: 404)
      end

      it "returns nil" do
        expect(attachable).to be_nil
      end
    end

    context "when socket error occurs" do
      before do
        stub_request(:get, url).to_raise(SocketError)
      end

      it "returns nil" do
        expect(attachable).to be_nil
      end
    end

    context "when timeout error occurs" do
      before do
        stub_request(:get, url).to_timeout
      end

      it "returns nil" do
        expect(attachable).to be_nil
      end
    end

    context "when the image bytes are corrupt" do
      before do
        allow(Vips::Image).to receive(:new_from_buffer).and_raise(Vips::Error, "bad image data")
        stub_request(:get, url).to_return(body: "corrupt-bytes", headers: { "Content-Type" => "image/png" })
      end

      it "returns nil" do
        expect(attachable).to be_nil
      end
    end
  end
end
