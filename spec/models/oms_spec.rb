# frozen_string_literal: true

require "rails_helper"

RSpec.describe OMS, type: :model, backend: true do
  it { should have_one(:trigger).dependent(:destroy) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:type) }

  # Couldn't get shoulda_matchers to work with conditional validations so I'm writing normal tests

  context "validate uniqueness of name" do
    subject { create(:oms) }
    it { should validate_uniqueness_of(:name) }
  end

  it "should validate single_default_oms?" do
    create(:default_oms)
    expect(build(:default_oms)).to_not be_valid
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
      expect(build(:resource_dedicated_oms, service: nil)).to be_valid
    end
  end

  context "provider group OMS" do
    it "should validate properly" do
      expect(build(:provider_group_oms)).to be_valid
      expect(build(:provider_group_oms, offers: [])).to be_valid
      expect(build(:provider_group_oms, offers: build_list(:offer, 2))).to be_valid
      expect(build(:provider_group_oms, service: build(:service))).to_not be_valid
      expect(build(:provider_group_oms, providers: [])).to be_valid
    end
  end

  context "#projects" do
    let(:project1) { create(:project) }
    let(:project2) { create(:project) }
    let(:default_oms) do
      create(
        :oms,
        offers: [
          create(:offer),
          create(:offer, project_items: [create(:project_item, project: project1)]),
          create(
            :offer,
            project_items: [create(:project_item, project: project1), create(:project_item, project: project2)]
          )
        ]
      )
    end

    let(:oms) do
      create(
        :default_oms,
        offers: [
          create(:offer, project_items: [create(:project_item, project: project1)]),
          create(:offer, project_items: [create(:project_item, project: project1)])
        ]
      )
    end
    let(:other_oms) { create(:oms, offers: create_list(:offer, 2)) }

    it "should return all project when oms is default" do
      expect(default_oms.projects).to contain_exactly(project1, project2)
    end

    it "should return only associated projects when oms is not default" do
      expect(oms.projects).to contain_exactly(project1)
      expect(other_oms.projects).to eq([])
    end
  end

  context "#project_items_for" do
    let(:oms1) { create(:oms) }
    let(:oms2) { create(:oms) }
    let(:default_oms) { create(:default_oms) }
    let(:project_items1) do
      [
        build(:project_item, offer: build(:offer, primary_oms: oms1)),
        build(:project_item, offer: build(:offer, primary_oms: oms1)),
        build(:project_item, offer: build(:offer, primary_oms: oms2)),
        build(:project_item, offer: build(:offer, primary_oms: oms1)),
        build(:project_item, offer: build(:offer, primary_oms: oms2))
      ]
    end
    let(:project_items2) do
      [
        build(:project_item, offer: build(:offer, primary_oms: oms1)),
        build(:project_item, offer: build(:offer, primary_oms: oms1))
      ]
    end
    let(:project) { create(:project, project_items: project_items1) }
    let(:other_project) { create(:project, project_items: project_items2) }

    it "returns only associated project_items for a single project" do
      expect(oms1.project_items_for(project)).to contain_exactly(
        project_items1[0],
        project_items1[1],
        project_items1[3]
      )
      expect(oms2.project_items_for(project)).to contain_exactly(project_items1[2], project_items1[4])

      expect(oms1.project_items_for(other_project)).to match_array(project_items2)
      expect(oms2.project_items_for(other_project)).to eq([])
    end

    it "returns all project_items for a single project for a default oms" do
      expect(default_oms.project_items_for(project)).to eq(project_items1)
      expect(default_oms.project_items_for(other_project)).to eq(project_items2)
    end
  end

  context "#events" do
    let(:default_oms) { create(:default_oms) }
    let(:oms) { create(:oms) }

    let!(:project1) { create(:project) }
    let!(:project2) { create(:project) }

    let!(:project_item1) { create(:project_item, project: project1, offer: build(:offer, primary_oms: default_oms)) }
    let!(:project_item2) { create(:project_item, project: project2, offer: build(:offer, primary_oms: oms)) }

    let!(:message1) { create(:message, messageable: project1) }
    let!(:message2) { create(:message, messageable: project_item1) }
    let!(:message3) { create(:message, messageable: project2) }
    let!(:message4) { create(:message, messageable: project_item2) }

    it "returns all events when oms is default" do
      events = default_oms.events.order(:created_at)
      expect(events.count).to eq(8)
      expect(events[0].eventable).to eq(project1)
      expect(events[1].eventable).to eq(project2)
      expect(events[2].eventable).to eq(project_item1)
      expect(events[3].eventable).to eq(project_item2)
      expect(events[4].eventable).to eq(message1)
      expect(events[5].eventable).to eq(message2)
      expect(events[6].eventable).to eq(message3)
      expect(events[7].eventable).to eq(message4)
    end

    it "returns proper events when oms is not default" do
      events = oms.events.order(:created_at)
      expect(events.count).to eq(4)
      expect(events[0].eventable).to eq(project2)
      expect(events[1].eventable).to eq(project_item2)
      expect(events[2].eventable).to eq(message3)
      expect(events[3].eventable).to eq(message4)
    end
  end

  context "#messages" do
    let(:oms1) { create(:oms) }
    let(:oms2) { create(:oms) }
    let(:default_oms) { create(:default_oms) }

    let(:project_item1) { create(:project_item, offer: create(:offer, primary_oms: oms1)) }
    let(:project_item2) { create(:project_item, offer: create(:offer, primary_oms: oms2)) }
    let(:project) { create(:project, project_items: [project_item1, project_item2]) }

    let!(:message1) { create(:message, messageable: project_item1) }
    let!(:message2) { create(:message, messageable: project_item2) }
    let!(:message3) { create(:message, messageable: project) }

    it "returns associated messages" do
      expect(oms1.messages).to contain_exactly(message1, message3)
      expect(oms2.messages).to contain_exactly(message2, message3)
      expect(default_oms.messages).to contain_exactly(message1, message2, message3)
    end
  end
end
