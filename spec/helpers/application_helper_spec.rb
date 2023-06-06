# frozen_string_literal: true

require "rails_helper"

describe ApplicationHelper, type: :helper, backend: true do
  context "#current_controller?" do
    before { allow(controller).to receive(:controller_name).and_return("foo") }

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

  context "#current_action?" do
    before { allow(controller).to receive(:action_name).and_return("foo") }

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

  context "#back_link_to" do
    it "returns to index for not persisted object" do
      expect(back_link_to("Back", build(:service))).to eq("<a href=\"#{services_path}\">Back</a>")
    end

    it "returns to show for persisted object" do
      service = create(:service)

      expect(back_link_to("Back", service)).to eq("<a href=\"#{service_path(service)}\">Back</a>")
    end

    it "respects prefix" do
      service = create(:service)

      expect(back_link_to("Back", service, prefix: :backoffice)).to eq(
        "<a href=\"#{backoffice_service_path(service)}\">Back</a>"
      )
    end

    it "passes html options" do
      expect(back_link_to("Back", build(:service), class: "btn")).to eq(
        "<a class=\"btn\" href=\"#{services_path}\">Back</a>"
      )
    end
  end
end
