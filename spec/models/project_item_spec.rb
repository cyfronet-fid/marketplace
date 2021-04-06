# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectItem do
  subject { create(:project_item) }

  it { should be_valid }
  it { should validate_presence_of(:offer) }
  it { should validate_presence_of(:project) }
  it { should validate_presence_of(:status) }
  it { should validate_presence_of(:status_type) }

  it { should belong_to(:project) }
  it { should belong_to(:offer) }

  describe "#new_status" do
    it "change project_item status" do
      project_item = create(:project_item, status: "created", status_type: :created)

      project_item.new_status(status: "custom_registered", status_type: :registered)
      new_status = project_item.statuses.last

      expect(project_item).to be_registered
      expect(project_item.status).to eq "custom_registered"
      expect(new_status).to be_registered
      expect(new_status.status).to eq "custom_registered"
    end

    it "set author" do
      project_item = create(:project_item, status: "created", status_type: :created)
      author = create(:user)

      project_item.new_status(status: "registered", status_type: :registered, author: author)
      new_status = project_item.statuses.last

      expect(new_status.author).to eq(author)
    end
  end

  describe "#active?" do
    it "is true when processing is not done" do
      expect(build(:project_item, status_type: :created)).to be_active
      expect(build(:project_item, status_type: :registered)).to be_active
      expect(build(:project_item, status_type: :in_progress)).to be_active
    end

    it "is false when processing is done" do
      expect(build(:project_item, status_type: :ready)).to_not be_active
      expect(build(:project_item, status_type: :rejected)).to_not be_active
    end
  end

  describe "#voucher_id" do
    it "can not be empty if offer supports vouchers and request_voucher is false" do
      subject = build(:project_item, request_voucher: false, offer: create(:offer, voucherable: true))
      expect(subject).to validate_presence_of(:voucher_id)
    end

    it "must be empty if offer supports vouchers and request_voucher is true" do
      subject = build(:project_item, request_voucher: true, offer: create(:offer, voucherable: true))
      expect(subject).to validate_absence_of(:voucher_id)
    end

    it "must be empty and request_voucher must be false if voucherable is false" do
      subject = build(:project_item, offer: create(:offer, voucherable: false))
      expect(subject).to validate_absence_of(:voucher_id)
      expect(subject).to validate_absence_of(:request_voucher)
    end
  end

  context "#properties" do
    it "should disallow null" do
      expect(build(:project_item, properties: nil).valid?).to be_falsey
    end

    it "should defaults to []" do
      expect(create(:project_item).reload.properties).to eq([])
    end
  end

  context "events" do
    it "should create an event on create" do
      project = create(:project)
      project_item = create(:project_item, project: project)

      expect(project.events.count).to eq(1)

      expect(project_item.events.count).to eq(1)
      expect(project_item.events.first.eventable).to eq(project_item)
      expect(project_item.events.first.action).to eq("create")
      expect(project_item.events.first.additional_info).to eq({ eventable_type: "ProjectItem",
                                                                project_id: project.id,
                                                                project_item_id: project_item.iid }.stringify_keys)
    end

    it "should create an event on update" do
      project = create(:project)

      project_item = create(:project_item, project: project, status_type: "created", status: "custom created status")
      project_item.update(status_type: "ready", status: "custom ready status")

      expect(project.events.count).to eq(1)

      expect(project_item.events.count).to eq(2)
      expect(project_item.events.first.eventable).to eq(project_item)
      expect(project_item.events.first.action).to eq("create")
      expect(project_item.events.first.additional_info).to eq({ eventable_type: "ProjectItem",
                                                                project_id: project.id,
                                                                project_item_id: project_item.iid }.stringify_keys)

      expect(project_item.events.second.eventable).to eq(project_item)
      expect(project_item.events.second.action).to eq("update")
      expect(project_item.events.second.updates).to contain_exactly({ field: "status_type", before: "created", after: "ready" }.stringify_keys,
                                                      { field: "status", before: "custom created status", after: "custom ready status" }.stringify_keys)
      expect(project_item.events.second.additional_info).to eq({ eventable_type: "ProjectItem",
                                                                project_id: project.id,
                                                                project_item_id: project_item.iid }.stringify_keys)
    end

    it "should create an event on delete" do
      project = create(:project)
      p_id = project.id

      project_item = create(:project_item, project: project)
      pi_id = project_item.iid
      project_item.destroy

      expect(project.events.count).to eq(1)

      expect(Event.count).to eq(3)
      expect(Event.second.eventable).to eq(nil)
      expect(Event.second.action).to eq("create")
      expect(Event.second.additional_info).to eq({ eventable_type: "ProjectItem",
                                                   project_id: p_id,
                                                   project_item_id: pi_id }.stringify_keys)

      expect(Event.third.eventable).to eq(nil)
      expect(Event.third.action).to eq("delete")
      expect(Event.third.additional_info).to eq({ eventable_type: "ProjectItem",
                                                   project_id: p_id,
                                                   project_item_id: pi_id }.stringify_keys)
    end
  end

  context "#user_secrets" do
    it "should allow empty hash" do
      expect(create(:project_item, user_secrets: {})).to be_valid
    end

    it "should default to empty hash" do
      expect(create(:project_item).reload.user_secrets).to eq({})
    end

    it "should forbid non-string values" do
      subject = build(:project_item, user_secrets: { "key" => 123 })
      subject.valid?
      expect(subject.errors[:user_secrets].size).to eq(1)
    end

    it "should allow string values" do
      expect(build(:project_item, user_secrets: { "key" => "123" })).to be_valid
    end
  end
end
