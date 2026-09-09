# frozen_string_literal: true

require "rails_helper"

RSpec.describe Checkin::Config, type: :service do
  let(:client_options) do
    {
      identifier: "client-id",
      secret: "client-secret",
      scheme: "https",
      host: "aai.eosc-portal.eu",
      port: nil,
      token_endpoint: "/auth/realms/core/protocol/openid-connect/token",
      introspection_uri: "https://aai.eosc-portal.eu/auth/realms/core/protocol/openid-connect/token/introspect"
    }
  end

  describe ".client_options" do
    it "reads client_options from the checkin omniauth strategy" do
      strategy = OmniAuth::Strategy::Options.new(client_options: client_options)
      checkin_config = instance_double(Devise::OmniAuth::Config, strategy: strategy)
      allow(Devise).to receive(:omniauth_configs).and_return(checkin: checkin_config)

      expect(described_class.client_options.to_h.symbolize_keys).to eq(client_options)
    end
  end

  describe ".become_vo_member_url" do
    it "reads the URL from BECOME_VO_MEMBER_URL when set" do
      allow(ENV).to receive(:fetch).with("BECOME_VO_MEMBER_URL", anything).and_return("https://example.com/enroll")

      expect(described_class.become_vo_member_url).to eq("https://example.com/enroll")
    end

    context "when BECOME_VO_MEMBER_URL is not set" do
      before do
        allow(ENV)
          .to receive(:fetch)
          .with("BECOME_VO_MEMBER_URL", anything)
          .and_wrap_original { |_method, _key, default| default }
      end

      it "falls back to the default sandbox enrollment URL" do
        expect(described_class.become_vo_member_url).to eq(
          "https://core-proxy.sandbox.eosc-beyond.eu/auth/realms/core/account/#/enroll?groupPath=/eosc-beyond.eu"
        )
      end
    end
  end

  describe ".vo_group_name" do
    it "reads the group name from VO_GROUP_NAME when set" do
      allow(ENV).to receive(:fetch).with("VO_GROUP_NAME", anything).and_return("some-other.vo")

      expect(described_class.vo_group_name).to eq("some-other.vo")
    end

    it "falls back to the default eosc-beyond.eu group" do
      allow(ENV)
        .to receive(:fetch)
        .with("VO_GROUP_NAME", anything)
        .and_wrap_original { |_method, _key, default| default }

      expect(described_class.vo_group_name).to eq("eosc-beyond.eu")
    end
  end

  describe ".introspection_url" do
    it "returns the already-absolute introspection_uri unchanged" do
      expect(described_class.introspection_url(client_options)).to eq(client_options[:introspection_uri])
    end
  end

  describe ".token_url" do
    it "builds an absolute URL from scheme, host and the relative token_endpoint path" do
      expect(described_class.token_url(client_options))
        .to eq("https://aai.eosc-portal.eu/auth/realms/core/protocol/openid-connect/token")
    end

    it "includes the port when one is present" do
      expect(described_class.token_url(client_options.merge(port: 8443)))
        .to eq("https://aai.eosc-portal.eu:8443/auth/realms/core/protocol/openid-connect/token")
    end
  end
end
