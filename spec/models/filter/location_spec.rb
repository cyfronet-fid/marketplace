# frozen_string_literal: true

require "rails_helper"

RSpec.describe Filter::Location, :backend do
  describe "#options" do
    let(:filter) { described_class.new }
    let(:european_union) { Country.for("EU") }
    let(:poland) { Country.for("PL") }
    let!(:service_with_countries) { create(:service, geographical_availabilities: %w[PL EU]) }
    let!(:unpublished_service) { create(:service, status: :unpublished, geographical_availabilities: ["DE"]) }
    let!(:service_without_countries) do
      build(:service, geographical_availabilities: []).tap { |service| service.save(validate: false) }
    end

    it "lists the countries of the published services and skips a service without countries" do
      expect(filter.options).to contain_exactly(
        { name: "Any", id: "" },
        { name: european_union, id: european_union },
        { name: poland, id: poland }
      )
    end
  end
end
