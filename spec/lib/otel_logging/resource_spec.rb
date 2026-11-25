# frozen_string_literal: true

require "rails_helper"
require_relative "../../../lib/otel_logging/resource"

RSpec.describe OtelLogging::Resource do
  subject(:fields) { described_class.from_env(env, service_name: "web").to_h }

  context "with the variables of a staging deployment" do
    let(:env) do
      {
        "MP_VERSION" => "mp-multitenancy-pl 0123abc",
        "SENTRY_ENVIRONMENT" => "staging",
        "RAILS_ENV" => "production",
        "MARKETPLACE_VARIANT" => "pl",
        "ROOT_URL" => "https://marketplace-16.example.org"
      }
    end

    it "gives marketplace as the service namespace" do
      expect(fields["service.namespace"]).to eq("marketplace")
    end

    it "gives the service name" do
      expect(fields["service.name"]).to eq("web")
    end

    it "gives the commit of MP_VERSION as the service version" do
      expect(fields["service.version"]).to eq("0123abc")
    end

    it "gives SENTRY_ENVIRONMENT as the deployment environment" do
      expect(fields["deployment.environment.name"]).to eq("staging")
    end

    it "gives the variant" do
      expect(fields["mp.variant"]).to eq("pl")
    end

    it "gives the host of ROOT_URL as the instance" do
      expect(fields["mp.instance"]).to eq("marketplace-16.example.org")
    end
  end

  context "without SENTRY_ENVIRONMENT" do
    let(:env) { { "RAILS_ENV" => "production" } }

    it "gives RAILS_ENV as the deployment environment" do
      expect(fields["deployment.environment.name"]).to eq("production")
    end
  end

  context "without the variables" do
    let(:env) { {} }

    it "gives the service namespace and the service name only" do
      expect(fields).to eq("service.namespace" => "marketplace", "service.name" => "web")
    end
  end
end
