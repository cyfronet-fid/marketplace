# frozen_string_literal: true

require "rails_helper"

RSpec.describe Tourable, type: :controller, backend: true do
  controller(ActionController::Base) do
    attr_accessor :available_tours
    attr_reader :tour

    include Tourable
  end

  context "default activation tour" do
    it "should choose an implicit tour" do
      controller.available_tours = { "implicitly_default_tour" => {} }

      controller.send(:determine_tour)

      expect(controller.tour[:name]).to eq("implicitly_default_tour")
    end

    it "should choose an explicit tour" do
      controller.available_tours = { "explicitly_default_tour" => { "activation_strategy" => "default" } }

      controller.send(:determine_tour)

      expect(controller.tour[:name]).to eq("explicitly_default_tour")
    end
  end

  context "query_param tour" do
    it "should prefer query param tour" do
      controller.params = { tour: "some_tour" }
      controller.available_tours = {
        "explicitly_default_tour" => {
          "activation_strategy" => "default"
        },
        "implicitly_default_tour" => {
        },
        "some_tour" => {
          "activation_strategy" => "query_param"
        }
      }

      controller.send(:determine_tour)

      expect(controller.tour[:name]).to eq("some_tour")
    end

    it "shouldn't choose query param tour if param is missing" do
      controller.params = { tour: "missing_tour" }
      controller.available_tours = { "some_tour" => { "activation_strategy" => "query_param" } }

      controller.send(:determine_tour)

      expect(controller.tour).to eq({})
    end
  end

  context "unknown activation tour" do
    it "should ignore an unknown activation" do
      controller.available_tours = { "implicitly_default_tour" => { "activation_strategy" => "unknown" } }

      controller.send(:determine_tour)

      expect(controller.tour).to eq({})
    end
  end
end
