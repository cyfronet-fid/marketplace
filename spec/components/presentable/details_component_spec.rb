# frozen_string_literal: true

require "rails_helper"

RSpec.describe Presentable::DetailsComponent, type: :component do
  describe "resource predicates" do
    it "identifies deployable applications by their resource type" do
      component = described_class.new(double(resource_type: "DeployableApplication"))

      expect(component).to be_deployable_application
      expect(component).not_to be_service
    end

    it "identifies services case-insensitively by their resource type" do
      component = described_class.new(double(resource_type: "SERVICE"))

      expect(component).to be_service
      expect(component).not_to be_deployable_application
    end

    it "handles objects without a resource type" do
      component = described_class.new(Object.new)

      expect(component).not_to be_service
      expect(component).not_to be_deployable_application
    end

    it "identifies catalogues and providers by class" do
      expect(described_class.new(Catalogue.new)).to be_catalogue
      expect(described_class.new(Provider.new)).to be_provider
    end
  end
end
