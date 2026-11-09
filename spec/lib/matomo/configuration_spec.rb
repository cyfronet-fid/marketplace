# frozen_string_literal: true

require "rails_helper"

RSpec.describe Matomo::Configuration do
  subject(:configuration) { described_class.new(env) }

  let(:site) { { "MP_MATOMO_URL" => "https://matomo.example.org/", "MP_MATOMO_SITE_ID" => "12" } }

  context "without MP_MATOMO_ENABLED" do
    let(:env) { site }

    it { is_expected.not_to be_enabled }
  end

  context "with MP_MATOMO_ENABLED=false" do
    let(:env) { site.merge("MP_MATOMO_ENABLED" => "false") }

    it { is_expected.not_to be_enabled }
  end

  context "with MP_MATOMO_ENABLED=true" do
    let(:env) { site.merge("MP_MATOMO_ENABLED" => "true") }

    it { is_expected.to be_enabled }
    it { is_expected.to have_attributes(url: "https://matomo.example.org/", site_id: "12") }
    it { is_expected.to have_attributes(token_auth: nil, sync_cron: "15 2 * * *") }
  end

  context "with the sync settings" do
    let(:env) do
      site.merge(
        "MP_MATOMO_ENABLED" => "true",
        "MP_MATOMO_TOKEN_AUTH" => "secret",
        "MP_MATOMO_SYNC_CRON" => "0 4 * * *"
      )
    end

    it { is_expected.to have_attributes(token_auth: "secret", sync_cron: "0 4 * * *") }

    it "keeps the token out of logs and consoles" do
      expect(configuration.inspect).not_to include("secret")
    end
  end

  context "when enabled without MP_MATOMO_URL" do
    let(:env) { { "MP_MATOMO_ENABLED" => "true", "MP_MATOMO_SITE_ID" => "12" } }

    it "refuses to boot" do
      expect { configuration }.to raise_error(Matomo::Configuration::Error, /MP_MATOMO_URL is required/)
    end
  end

  context "when enabled without MP_MATOMO_SITE_ID" do
    let(:env) { { "MP_MATOMO_ENABLED" => "true", "MP_MATOMO_URL" => "https://matomo.example.org/" } }

    it "refuses to boot" do
      expect { configuration }.to raise_error(Matomo::Configuration::Error, /MP_MATOMO_SITE_ID is required/)
    end
  end

  context "when enabled with a blank MP_MATOMO_SITE_ID" do
    let(:env) { site.merge("MP_MATOMO_ENABLED" => "true", "MP_MATOMO_SITE_ID" => " ") }

    it "refuses to boot" do
      expect { configuration }.to raise_error(Matomo::Configuration::Error, /MP_MATOMO_SITE_ID is required/)
    end
  end

  context "with MP_MATOMO_URL without a trailing slash" do
    let(:env) { site.merge("MP_MATOMO_ENABLED" => "true", "MP_MATOMO_URL" => "https://matomo.example.org") }

    it { is_expected.to have_attributes(url: "https://matomo.example.org/") }
  end

  context "with MP_MATOMO_URL on a path" do
    let(:env) { site.merge("MP_MATOMO_ENABLED" => "true", "MP_MATOMO_URL" => "http://example.org/matomo") }

    it { is_expected.to have_attributes(url: "http://example.org/matomo/") }
  end

  context "with a protocol-relative MP_MATOMO_URL" do
    let(:env) { site.merge("MP_MATOMO_ENABLED" => "true", "MP_MATOMO_URL" => "//matomo.example.org/") }

    it "refuses to boot" do
      expect { configuration }.to raise_error(Matomo::Configuration::Error, /MP_MATOMO_URL must be an absolute/)
    end
  end

  context "with MP_MATOMO_URL without a scheme" do
    let(:env) { site.merge("MP_MATOMO_ENABLED" => "true", "MP_MATOMO_URL" => "matomo.example.org") }

    it "refuses to boot" do
      expect { configuration }.to raise_error(Matomo::Configuration::Error, /MP_MATOMO_URL must be an absolute/)
    end
  end

  context "when disabled without MP_MATOMO_URL and MP_MATOMO_SITE_ID" do
    let(:env) { { "MP_MATOMO_ENABLED" => "false" } }

    it { is_expected.not_to be_enabled }
  end
end
