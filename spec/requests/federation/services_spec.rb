# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Federation services" do
  subject(:federation_response) do
    get federation_services_path(format: request_format, nodes: ["21.T15999/CESSDA"])
    response
  end

  let(:api_url) { "https://federation.example.org/federation/services" }
  let(:request_format) { :json }

  let(:service) do
    {
      "id" => "service/S1Ux8C",
      "name" => "CESSDA Data Catalogue",
      "description" => "Find social science data",
      "webpage" => "https://www.cessda.eu/Tools/Data-Catalogue",
      "logo" => "https://www.cessda.eu/logo.svg",
      "nodePID" => "21.T15999/CESSDA",
      "type" => "Service"
    }.merge(service_overrides)
  end

  let(:service_overrides) { {} }
  let(:results) { [{ "score" => 0.04, "result" => service }] }

  let(:node) do
    {
      "pid" => "21.T15999/CESSDA",
      "name" => "CESSDA",
      "capabilities" => [{ "capability_type" => "Front Office", "endpoint" => "https://cessda.example.org" }]
    }.merge(node_overrides)
  end

  let(:node_overrides) { {} }

  let(:facets) { [] }
  let(:returned_results) { JSON.parse(federation_response.body)["results"] }

  before do
    allow(Mp::Application.config).to receive_messages(federation_api_base_url: api_url, aggregator_type: "pc")
    body = { "total" => results.size, "results" => results, "facets" => facets, "metadata" => { "nodes" => [node] } }
    stub_request(:get, /federation\.example\.org/).to_return(status: 200, body: body.to_json)
  end

  context "when the federation API returns services" do
    it "responds with 200" do
      expect(federation_response).to have_http_status(:ok)
    end

    it "returns the mapped services" do
      expect(returned_results.pluck("name")).to eq(["CESSDA Data Catalogue"])
    end

    context "with a service without a logo" do
      let(:service_overrides) { { "logo" => nil } }

      it "returns the service without a logo" do
        expect(returned_results.pluck("logo")).to eq([nil])
      end
    end

    context "with a service without a name, description or webpage" do
      let(:service_overrides) { { "name" => nil, "description" => nil, "webpage" => "" } }

      it "returns the service" do
        expect(returned_results.pluck("pid")).to eq(["service/S1Ux8C"])
      end

      it "returns no webpage" do
        expect(returned_results.pluck("webpage")).to eq([nil])
      end
    end

    context "with a service with an empty webpage and a nested service webpage" do
      let(:service_overrides) { { "webpage" => "", "service" => { "webpage" => "https://nested.example.org" } } }

      it "returns the nested service webpage" do
        expect(returned_results.pluck("webpage")).to eq(["https://nested.example.org"])
      end
    end

    context "with a result without a service object" do
      let(:results) { [{ "score" => 0.04, "result" => nil }, { "score" => 0.04, "result" => service }] }

      it "skips it and returns the other services" do
        expect(returned_results.pluck("name")).to eq(["CESSDA Data Catalogue"])
      end
    end

    context "with a result that cannot be mapped" do
      let(:results) do
        [{ "result" => service.merge("name" => "Broken", "scientificDomains" => [1]) }, { "result" => service }]
      end

      it "skips it and returns the other services" do
        expect(returned_results.pluck("name")).to eq(["CESSDA Data Catalogue"])
      end
    end

    context "with a node without a pid" do
      let(:node_overrides) { { "pid" => nil } }

      it "returns the services" do
        expect(returned_results.pluck("name")).to eq(["CESSDA Data Catalogue"])
      end
    end

    context "with a node without capabilities" do
      let(:node_overrides) { { "capabilities" => nil } }

      it "returns the services" do
        expect(returned_results.pluck("name")).to eq(["CESSDA Data Catalogue"])
      end
    end

    context "with facets that cannot be mapped" do
      let(:facets) { [1] }

      it "responds with 500" do
        expect(federation_response).to have_http_status(:internal_server_error)
      end
    end
  end

  context "when the federation API fails" do
    before { stub_request(:get, /federation\.example\.org/).to_return(status: 503) }

    it "responds with 502" do
      expect(federation_response).to have_http_status(:bad_gateway)
    end

    context "with an HTML request" do
      let(:request_format) { :html }

      it "renders the search page with 502" do
        expect(federation_response).to have_http_status(:bad_gateway)
      end
    end
  end

  context "when the federation API returns invalid JSON" do
    before { stub_request(:get, /federation\.example\.org/).to_return(status: 200, body: "<html>oops</html>") }

    it "responds with 502" do
      expect(federation_response).to have_http_status(:bad_gateway)
    end
  end

  context "when the federation API times out" do
    before { stub_request(:get, /federation\.example\.org/).to_raise(Net::ReadTimeout) }

    it "responds with 504" do
      expect(federation_response).to have_http_status(:gateway_timeout)
    end
  end

  context "when the federation API is not configured" do
    let(:api_url) { "" }

    it "responds with 503" do
      expect(federation_response).to have_http_status(:service_unavailable)
    end
  end
end
