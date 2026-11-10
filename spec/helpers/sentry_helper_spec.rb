# frozen_string_literal: true

require "rails_helper"

describe SentryHelper, :backend do
  context "without SENTRY_DSN" do
    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("SENTRY_DSN", nil).and_return(nil)
      allow(helper).to receive(:current_user).and_return(nil)
    end

    it "gives no tags" do
      expect(helper.sentry_browser_tags).to be_nil
    end
  end

  context "with SENTRY_DSN and no signed-in user" do
    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("SENTRY_DSN", nil).and_return("https://key@glitchtip.example/1")
      allow(ENV).to receive(:[]).with("SENTRY_ENVIRONMENT").and_return("staging")
      allow(ENV).to receive(:fetch).with("MP_VERSION", "").and_return("mp-multitenancy-pl 0123abc")
      allow(helper).to receive(:current_user).and_return(nil)
    end

    it "gives the dsn tag" do
      expect(helper.sentry_browser_tags).to include('name="sentry-dsn" content="https://key@glitchtip.example/1"')
    end

    it "gives the environment tag" do
      expect(helper.sentry_browser_tags).to include('name="sentry-environment" content="staging"')
    end

    it "gives the commit of MP_VERSION as the release tag" do
      expect(helper.sentry_browser_tags).to include('name="sentry-release" content="0123abc"')
    end

    it "gives no user tags" do
      expect(helper.sentry_browser_tags).not_to include("sentry-user-id")
    end
  end

  context "with SENTRY_DSN and a signed-in user" do
    let(:user) { build_stubbed(:user) }

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("SENTRY_DSN", nil).and_return("https://key@glitchtip.example/1")
      allow(helper).to receive(:current_user).and_return(user)
    end

    it "gives the user id tag" do
      expect(helper.sentry_browser_tags).to include(%(name="sentry-user-id" content="#{user.id}"))
    end

    it "gives the user uid tag" do
      expect(helper.sentry_browser_tags).to include(%(name="sentry-user-uid" content="#{user.uid}"))
    end
  end

  context "with SENTRY_DSN and no MP_VERSION" do
    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("SENTRY_DSN", nil).and_return("https://key@glitchtip.example/1")
      allow(ENV).to receive(:fetch).with("MP_VERSION", "").and_return("")
      allow(helper).to receive(:current_user).and_return(nil)
    end

    it "gives no release tag" do
      expect(helper.sentry_browser_tags).not_to include("sentry-release")
    end
  end
end
