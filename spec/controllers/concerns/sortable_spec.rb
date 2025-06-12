# frozen_string_literal: true

require "rails_helper"

class SortableFakeController < ApplicationController
  attr_accessor :params

  def initialize
    super
    @params = {}
  end

  include Service::Sortable
end

RSpec.describe SortableFakeController, backend: true do
  let!(:controller) { SortableFakeController.new }

  context "ordering" do
    it "should by default sort by name" do
      expect(controller.send(:ordering)).to eq(sort_name: { order: :asc, unmapped_type: :string })
    end

    it "should return ascending ordering by rating" do
      controller.params = { sort: "rating" }
      expect(controller.send(:ordering)).to eq("rating" => { order: :asc, unmapped_type: :long })
    end
    it "should return descending ordering by rating" do
      controller.params = { sort: "-rating" }
      expect(controller.send(:ordering)).to eq("rating" => { order: :desc, unmapped_type: :long })
    end
    it "should return ascending ordering by status" do
      controller.params = { sort: "status" }
      expect(controller.send(:ordering)).to eq("status" => { order: :asc, unmapped_type: :string })
    end
    it "should return ascending ordering by status" do
      controller.params = { sort: "-status" }
      expect(controller.send(:ordering)).to eq("status" => { order: :desc, unmapped_type: :string })
    end
  end
end
