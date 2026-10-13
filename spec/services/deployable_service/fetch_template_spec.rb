# frozen_string_literal: true

require "rails_helper"

RSpec.describe DeployableService::FetchTemplate, type: :service do
  let(:raw_url) { "https://raw.githubusercontent.com/grycap/tosca/eosc_beyond/templates/jupyter.yml" }

  it "fetches the raw template for a GitHub blob URL" do
    stub_request(:get, raw_url).to_return(status: 200, body: "tosca_definitions_version: tosca_simple_yaml_1_0")

    result = described_class.call("https://github.com/grycap/tosca/blob/eosc_beyond/templates/jupyter.yml")

    expect(result).to eq("tosca_definitions_version: tosca_simple_yaml_1_0")
  end

  it "fetches non-GitHub URLs as given" do
    stub_request(:get, "https://example.com/template.yml").to_return(status: 200, body: "template")

    expect(described_class.call("https://example.com/template.yml")).to eq("template")
  end

  it "raises an HTTP error when the template cannot be fetched" do
    stub_request(:get, raw_url).to_return(status: [404, "Not Found"])

    expect { described_class.call(raw_url) }.to raise_error(Net::HTTPError, /HTTP 404/)
  end
end
