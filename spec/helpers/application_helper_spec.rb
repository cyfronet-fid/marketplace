# frozen_string_literal: true

require "rails_helper"

describe ApplicationHelper, type: :helper do
  describe "current_controller?" do
    before do
      allow(controller).to receive(:controller_name).and_return("foo")
    end

    it "returns true when controller matches argument" do
      expect(current_controller?(:foo)).to be_truthy
    end

    it "returns false when controller does not match argument" do
      expect(current_controller?(:bar)).to be_falsy
    end

    it "should take any number of arguments" do
      expect(current_controller?(:baz, :bar)).to be_falsy
      expect(current_controller?(:baz, :bar, :foo)).to be_truthy
    end
  end

  describe "current_action?" do
    before do
      allow(controller).to receive(:action_name).and_return("foo")
    end

    it "returns true when action matches argument" do
      expect(current_action?(:foo)).to be_truthy
    end

    it "returns false when action does not match argument" do
      expect(current_action?(:bar)).to be_falsy
    end

    it "should take any number of arguments" do
      expect(current_action?(:baz, :bar)).to be_falsy
      expect(current_action?(:baz, :bar, :foo)).to be_truthy
    end
  end
end
