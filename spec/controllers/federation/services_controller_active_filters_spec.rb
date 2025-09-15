# frozen_string_literal: true

require "rails_helper"

RSpec.describe Federation::ServicesController, type: :controller do
  describe "#active_filters" do
    before { allow(controller).to receive(:remove_filter_url).and_return("#") }
    it "does not include child facet when its parent is also selected" do
      # Build a simple facets tree: Parent -> Child
      options = [{ "eid" => "p", "name" => "Parent", "children" => [{ "eid" => "c", "name" => "Child" }] }]

      controller.instance_variable_set(:@facets, { "domains" => options })

      params_hash = ActionController::Parameters.new(domains: %w[p c])
      allow(controller).to receive(:params).and_return(params_hash)

      filters = controller.send(:active_filters)
      names = filters.map { |f| f[:name] }

      expect(names).to include("Domains: Parent")
      expect(names).not_to include("Domains: Child")
    end

    it "includes child facet when parent is not selected" do
      options = [{ "eid" => "p", "name" => "Parent", "children" => [{ "eid" => "c", "name" => "Child" }] }]

      controller.instance_variable_set(:@facets, { "domains" => options })

      params_hash = ActionController::Parameters.new(domains: %w[c])
      allow(controller).to receive(:params).and_return(params_hash)

      filters = controller.send(:active_filters)
      names = filters.map { |f| f[:name] }

      expect(names).to include("Domains: Child")
      expect(names).not_to include("Domains: Parent")
    end
  end
end
