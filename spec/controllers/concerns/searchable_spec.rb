# frozen_string_literal: true

require "rails_helper"

class SearchableFakeController < ApplicationController
  attr_accessor :params

  def initialize
    @params = ActionController::Parameters.new(providers: [1])
  end

  include Service::Searchable
end

RSpec.describe SearchableFakeController do
  let!(:platform_1) { create(:platform) }
  let!(:platform_2) { create(:platform) }
  let!(:provider_1) { create(:provider) }
  let!(:provider_2) { create(:provider) }
  let!(:target_group) { create(:target_group) }
  let!(:service_1) do  create(:service,
                              providers: [provider_1],
                              target_groups: [target_group],
                              platforms: [platform_1])
  end
  let!(:service_2) do  create(:service,
                              providers: [provider_2],
                              target_groups: [target_group],
                              platforms: [platform_2])
  end
  let!(:category_1) { create(:category, services: [service_1, service_2]) }
  let!(:category_2) { create(:category, services: [service_2]) }
  let!(:controller) { SearchableFakeController.new }

  context "provider_options" do
    it "should count services depending on the category" do
      expect(controller.send(:options_providers, category_2).size).to eq(1)
      expect(controller.send(:options_providers, category_2).first).to eq([provider_2.name, provider_2.id, 1])
    end

    it "should count all services if no category is specified" do
      expect(controller.send(:options_providers).size).to eq(2)
      expect(controller.send(:options_providers)).to include([provider_2.name, provider_2.id, 1])
    end

  end

  context "target_groups_options" do
    it "should count services depending on the category 2" do
      expect(controller.send(:options_target_groups, category_2).size).to eq(1)
      expect(controller.send(:options_target_groups, category_2).first).to eq([target_group.name, target_group.id, 1])
    end

    it "should count services depending on the category 1" do
      expect(controller.send(:options_target_groups, category_1).size).to eq(1)
      expect(controller.send(:options_target_groups, category_1).first).to eq([target_group.name, target_group.id, 2])
    end

    it "should count all services if no category is specified" do
      expect(controller.send(:options_target_groups).size).to eq(1)
      expect(controller.send(:options_target_groups)).to include([target_group.name, target_group.id, 2])
    end
  end

  context "related_platform_options" do
    it "should count services depending on the category" do
      expect(controller.send(:options_related_platforms, category_2).size).to eq(1)
      expect(controller.send(:options_related_platforms, category_2)).to include([platform_2.name, platform_2.id, 1])
    end

    it "should count all services if no category is specified" do
      expect(controller.send(:options_related_platforms).size).to eq(2)
      expect(controller.send(:options_related_platforms)).to include([platform_2.name, platform_2.id, 1])
    end
  end

  context "active_filters" do
    it "should work" do
      controller.params = ActionController::Parameters.new("providers" => [provider_1.id.to_s, provider_2.id.to_s])
      expect(controller.send(:active_filters)).to eq([[provider_1.name, "providers" => [provider_2.id.to_s]],
                                                      [provider_2.name, "providers" => [provider_1.id.to_s]]])
    end
  end
end
