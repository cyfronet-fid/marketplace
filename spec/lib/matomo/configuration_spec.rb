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

    it("doesn't sync Views without the token") { is_expected.not_to be_views_synced }
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
    it { is_expected.to be_views_synced }

    it "keeps the token out of logs and consoles" do
      expect(configuration.inspect).not_to include("secret")
    end
  end

  context "with MP_MATOMO_TOKEN_AUTH while Matomo is off" do
    let(:env) { site.merge("MP_MATOMO_ENABLED" => "false", "MP_MATOMO_TOKEN_AUTH" => "secret") }

    it { is_expected.not_to be_views_synced }
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

  context "when enabled with a MP_MATOMO_SITE_ID of 0" do
    let(:env) { site.merge("MP_MATOMO_ENABLED" => "true", "MP_MATOMO_SITE_ID" => "0") }

    it "refuses to boot" do
      expect { configuration }.to raise_error(Matomo::Configuration::Error, /MP_MATOMO_SITE_ID must be a positive/)
    end
  end

  context "when enabled with a MP_MATOMO_SITE_ID that is not a number" do
    let(:env) { site.merge("MP_MATOMO_ENABLED" => "true", "MP_MATOMO_SITE_ID" => "12a") }

    it "refuses to boot" do
      expect { configuration }.to raise_error(Matomo::Configuration::Error, /MP_MATOMO_SITE_ID must be a positive/)
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

  context "with MP_MATOMO_URL ending in several slashes" do
    let(:env) { site.merge("MP_MATOMO_ENABLED" => "true", "MP_MATOMO_URL" => "https://example.org/matomo//") }

    it { is_expected.to have_attributes(url: "https://example.org/matomo/") }
  end

  context "with a query in MP_MATOMO_URL" do
    let(:env) { site.merge("MP_MATOMO_ENABLED" => "true", "MP_MATOMO_URL" => "https://example.org/matomo?site=1") }

    it "refuses to boot" do
      expect { configuration }.to raise_error(Matomo::Configuration::Error, /without a query or fragment/)
    end
  end

  context "with a fragment in MP_MATOMO_URL" do
    let(:env) { site.merge("MP_MATOMO_ENABLED" => "true", "MP_MATOMO_URL" => "https://example.org/matomo#setup") }

    it "refuses to boot" do
      expect { configuration }.to raise_error(Matomo::Configuration::Error, /without a query or fragment/)
    end
  end

  context "with MP_MATOMO_TOKEN_AUTH and an http MP_MATOMO_URL" do
    let(:env) do
      site.merge(
        "MP_MATOMO_ENABLED" => "true",
        "MP_MATOMO_URL" => "http://matomo.example.org/",
        "MP_MATOMO_TOKEN_AUTH" => "secret"
      )
    end

    it "refuses to boot, as the token would travel unencrypted" do
      expect { configuration }.to raise_error(Matomo::Configuration::Error, /must use https/)
    end
  end

  context "with MP_MATOMO_TOKEN_AUTH and an http MP_MATOMO_URL on this host" do
    let(:env) do
      site.merge(
        "MP_MATOMO_ENABLED" => "true",
        "MP_MATOMO_URL" => "http://localhost:8080/",
        "MP_MATOMO_TOKEN_AUTH" => "secret"
      )
    end

    it { is_expected.to have_attributes(url: "http://localhost:8080/", token_auth: "secret") }
  end

  context "with MP_MATOMO_TOKEN_AUTH and an http MP_MATOMO_URL on a loopback address" do
    let(:env) do
      site.merge("MP_MATOMO_ENABLED" => "true", "MP_MATOMO_URL" => "http://[::1]/", "MP_MATOMO_TOKEN_AUTH" => "secret")
    end

    it { is_expected.to have_attributes(url: "http://[::1]/") }
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
