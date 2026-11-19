# frozen_string_literal: true

require "rails_helper"

RSpec.describe Statistics::OrderCounts do
  subject(:order_counts) { described_class.call(services) }

  let(:service) { create(:service) }
  let(:services) { [service] }

  context "without Project items" do
    it { is_expected.to eq(service.id => 0) }
  end

  context "with a Project item of an internal 'order required' Offer" do
    before { create(:project_item, offer: create(:offer, service:)) }

    it { is_expected.to eq(service.id => 1) }
  end

  context "with a Project item of an external 'order required' Offer" do
    before { create(:project_item, offer: create(:offer, service:, internal: false)) }

    it { is_expected.to eq(service.id => 1) }
  end

  %w[open_access fully_open_access other].each do |order_type|
    context "with a Project item of an #{order_type} Offer" do
      let(:service) { create(:service, order_type:) }

      before { create(:project_item, offer: create(:offer, service:, order_type:)) }

      it("doesn't count it") { is_expected.to eq(service.id => 0) }
    end
  end

  context "with an Order in every status" do
    before do
      offer = create(:offer, service:)
      ProjectItem::STATUS_TYPES.each_value { |status| create(:project_item, offer:, status:, status_type: status) }
    end

    it("counts them all") { is_expected.to eq(service.id => 8) }
  end

  # A Project item keeps the order type its Offer had when it was created.
  context "with an Order whose Offer is open access now" do
    before do
      offer = create(:offer, service:)
      create(:project_item, offer:)
      offer.update_columns(order_type: "open_access") # rubocop:disable Rails/SkipsModelValidations
    end

    it("still counts it") { is_expected.to eq(service.id => 1) }
  end

  context "with an open access Project item whose Offer requires an order now" do
    let(:service) { create(:service, order_type: :open_access) }

    before do
      offer = create(:offer, service:, order_type: :open_access)
      create(:project_item, offer:)
      offer.update_columns(order_type: "order_required") # rubocop:disable Rails/SkipsModelValidations
    end

    it("still doesn't count it") { is_expected.to eq(service.id => 0) }
  end

  context "with a Project item of a bundled Offer" do
    let(:bundle) { create(:bundle, offers: [create(:offer, service:)]) }
    let(:services) { [service, bundle.service] }

    before { create(:project_item, offer: bundle.offers.first, bundle:) }

    it "counts it toward the Service of its own Offer, not the Bundle's" do
      expect(order_counts).to eq(service.id => 1, bundle.service.id => 0)
    end
  end

  # Offers belong to a Service or a Deployable Service through one polymorphic
  # orderable_id, so the ids of the two can be equal.
  context "with an Order of a Deployable Service with the same id", variant: :marketplace do
    before do
      deployable_service = create(:deployable_service, id: service.id)
      create(:project_item, offer: create(:offer, deployable_service:))
    end

    it("ignores it") { is_expected.to eq(service.id => 0) }
  end

  context "with a Datasource" do
    let(:service) { create(:datasource) }

    before { create(:project_item, offer: create(:offer, service:)) }

    it { is_expected.to eq(service.id => 1) }
  end

  context "with several Services" do
    let(:other) { create(:service) }
    let(:services) { [service, other] }

    before do
      create(:project_item, offer: create(:offer, service:))
      create_list(:project_item, 2, offer: create(:offer, service: other))
    end

    it("counts the Orders of each") { is_expected.to eq(service.id => 1, other.id => 2) }
  end
end
