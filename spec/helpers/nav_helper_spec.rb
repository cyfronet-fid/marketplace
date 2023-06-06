# frozen_string_literal: true

require "rails_helper"

describe NavHelper, backend: true do
  include ApplicationHelper

  describe "nav_link" do
    before do
      allow(controller).to receive(:controller_name).and_return("foo")
      allow(controller).to receive(:action_name).and_return("foo")
    end

    it "captures block output" do
      expect(nav_link { "Testing Blocks" }).to match(/Testing Blocks/)
    end

    it "performs checks on the current controller" do
      expect(nav_link(controller: :foo)).to match(/<li class="active">/)
      expect(nav_link(controller: :bar)).to_not match(/active/)
      expect(nav_link(controller: %i[foo bar])).to match(/active/)
    end

    it "performs checks on the current action" do
      expect(nav_link(action: :foo)).to match(/<li class="active">/)
      expect(nav_link(action: :bar)).to_not match(/active/)
      expect(nav_link(action: %i[foo bar])).to match(/active/)
    end

    it "performs checks on both controller and action when both are present" do
      expect(nav_link(controller: :bar, action: :foo)).to_not match(/active/)
      expect(nav_link(controller: :foo, action: :bar)).to_not match(/active/)
      expect(nav_link(controller: :foo, action: :foo)).to match(/active/)
    end

    it "accepts a path shorthand" do
      expect(nav_link(path: "foo#bar")).to_not match(/active/)
      expect(nav_link(path: "foo#foo")).to match(/active/)
    end

    it "passes active class option" do
      expect(nav_link(controller: :foo, active_class: "current-page")).to match(/<li class="current-page">/)
    end

    it "passes extra html options to the list element" do
      expect(nav_link(action: :foo, html_options: { class: "home" })).to match(/<li class="home active">/)
      expect(nav_link(html_options: { class: "active" })).to match(/<li class="active">/)
    end
  end

  describe "nav_tab" do
    it "captures block output" do
      expect(nav_tab(:key, "value") { "Testing Blocks" }).to match(/Testing Blocks/)
    end

    it "performs checks on params" do
      allow(controller).to receive(:params).and_return(foo: "bar")

      expect(nav_tab(:foo, "bar")).to match(/active/)
      expect(nav_tab(:foo, "other")).to_not match(/active/)
    end

    it "supports custom active class" do
      allow(controller).to receive(:params).and_return(foo: "bar")

      expect(nav_tab(:foo, "bar", active_class: "my_active")).to match(/my_active/)
    end
  end
end
