# frozen_string_literal: true

require "rails_helper"

RSpec.describe Oms, type: :model do
  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:type) }

  # Couldn't get shoulda_matchers to work with conditional validations so I'm writing normal tests

  context "validate uniqueness of name" do
    subject { create(:oms) }
    it { should validate_uniqueness_of(:name) }
  end

  it "should validate single_default_oms?" do
    create(:oms, default: true)
    expect(build(:oms, default: true)).to_not be_valid
  end

  it "should validate custom_params" do
    expect(build(:oms, custom_params: { a: { mandatory: false }, b: { mandatory: true, default: "ASD" } })).to be_valid
    expect(build(:oms, custom_params: nil)).to be_valid
    expect(build(:oms, custom_params: {})).to be_valid

    expect(build(:oms, custom_params: { a: { default: "ASD" } })).to_not be_valid
    expect(build(:oms, custom_params: { a: { mandatory: false, default: "ASD" } })).to_not be_valid
    expect(build(:oms, custom_params: { a: { mandatory: true } })).to_not be_valid
    expect(build(:oms, custom_params: { a: { mandatory: false }, b: { mandatory: true } })).to_not be_valid
    expect(build(:oms, custom_params: { a: 1 })).to_not be_valid
    expect(build(:oms, custom_params: { a: { b: 1 } })).to_not be_valid
  end

  context "global OMS" do
    it "should validate properly" do
      expect(build(:oms)).to be_valid
      expect(build(:oms, offers: [])).to be_valid
      expect(build(:oms, offers: build_list(:offer, 2))).to be_valid
      expect(build(:oms, providers: build_list(:provider, 2))).to_not be_valid
      expect(build(:oms, service: build(:service))).to_not be_valid
    end
  end

  context "resource dedicated OMS" do
    it "should validate properly" do
      expect(build(:resource_dedicated_oms)).to be_valid
      expect(build(:resource_dedicated_oms, offers: [])).to be_valid
      expect(build(:resource_dedicated_oms, offers: build_list(:offer, 2))).to be_valid
      expect(build(:resource_dedicated_oms, providers: build_list(:provider, 2))).to_not be_valid
      expect(build(:resource_dedicated_oms, service: nil)).to_not be_valid
    end
  end

  context "provider group OMS" do
    it "should validate properly" do
      expect(build(:provider_group_oms)).to be_valid
      expect(build(:provider_group_oms, offers: [])).to be_valid
      expect(build(:provider_group_oms, offers: build_list(:offer, 2))).to be_valid
      expect(build(:provider_group_oms, service: build(:service))).to_not be_valid
      expect(build(:provider_group_oms, providers: [])).to_not be_valid
    end
  end
end
