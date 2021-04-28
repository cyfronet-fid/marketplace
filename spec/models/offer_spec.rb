# frozen_string_literal: true

require "rails_helper"

RSpec.describe Offer do
  describe "validations" do
    subject { build(:offer) }
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:description) }
    it { should validate_presence_of(:service) }
    it { should validate_presence_of(:order_type) }
    it { should belong_to(:service) }

    it { should have_many(:project_items).dependent(:restrict_with_error) }
  end

  context "is open access" do
    subject { build(:offer, order_type: :open_access) }
    it { should_not validate_presence_of(:webpage) }
  end

  context "is external" do
    subject { build(:offer, order_type: :order_required, order_url: "http://order.com") }
    it { should_not validate_presence_of(:webpage) }
  end

  context "is orderable" do
    subject { build(:offer, order_type: :order_required) }
    it { should_not validate_presence_of(:webpage) }
  end

  context "OMS dependencies" do
    it "validates properly against primary oms" do
      oms = create(:oms, custom_params: { a: { mandatory: false }, b: { mandatory: true, default: "XD" } })

      expect(build(:offer, oms_params: { a: 1, b: 2 }, primary_oms: oms)).to be_valid
      expect(build(:offer, oms_params: { b: 1 }, primary_oms: oms)).to be_valid

      expect(build(:offer, oms_params: { a: 1 }, primary_oms: oms)).to_not be_valid
      expect(build(:offer, oms_params: { a: 1, b: 1, c: 1 }, primary_oms: oms)).to_not be_valid
      expect(build(:offer, oms_params: nil, primary_oms: oms)).to_not be_valid
      expect(build(:offer, oms_params: { b: 1, c: 1 }, primary_oms: build(:oms, custom_params: nil))).to_not be_valid

      expect(build(:offer, oms_params: { c: 1 }, primary_oms: nil)).to_not be_valid
      create(:oms, default: true, custom_params: { c: { mandatory: true, default: "c" } })
      expect(build(:offer, oms_params: { c: 1 }, primary_oms: nil)).to be_valid

      laid_back_oms = create(:oms, custom_params: { d: { mandatory: false } })
      expect(build(:offer, oms_params: nil, primary_oms: laid_back_oms)).to be_valid
    end

    it "returns proper current_oms" do
      oms = create(:oms)
      expect(build(:offer, primary_oms: oms).current_oms).to eql(oms)
      expect(build(:offer, primary_oms: nil).current_oms).to be_nil

      default_oms = create(:oms, default: true)
      expect(build(:offer, primary_oms: oms).current_oms).to eql(oms)
      expect(build(:offer, primary_oms: nil).current_oms).to eql(default_oms)
    end
  end

  context "#parameters" do
    it "should defaults to []" do
      expect(create(:offer).reload.parameters).to eq([])
    end
  end
end
