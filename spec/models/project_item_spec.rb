# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectItem do
  subject { create(:project_item) }

  it { should validate_presence_of(:offer) }
  it { should validate_presence_of(:project) }
  it { should validate_presence_of(:status) }

  it { should belong_to(:project) }
  it { should belong_to(:affiliation).required(false) }
  it { should belong_to(:offer) }
  it { should have_many(:project_item_changes).dependent(:destroy) }

  context "#research_area" do
    it "can be a leaf" do
      leaf = create(:research_area)

      expect(build(:project_item, research_area: leaf)).to be_valid
    end

    it "cannot have children" do
      root = create(:research_area)
      create(:research_area, parent: root)

      project_item = build(:project_item, research_area: root)

      expect(project_item).to_not be_valid
      expect(project_item.errors[:research_area_id]).to_not be_empty
    end
  end

  describe "#new_change" do
    it "change is not created when no message and status is given" do
      project_item = create(:project_item)

      expect { project_item.new_change }.to_not change { ProjectItemChange.count }
    end

    it "change project_item status" do
      project_item = create(:project_item, status: :created)

      project_item.new_change(status: :registered, message: "ProjectItem registered")
      project_item_change = project_item.project_item_changes.last

      expect(project_item).to be_registered
      expect(project_item_change).to be_registered
      expect(project_item_change.message).to eq("ProjectItem registered")
    end

    it "does not change status when only message is given" do
      project_item = create(:project_item, status: :created)

      project_item.new_change(message: "some update")
      project_item_change = project_item.project_item_changes.last

      expect(project_item).to be_created
      expect(project_item_change).to be_created
      expect(project_item_change.message).to eq("some update")
    end

    it "set change author" do
      project_item = create(:project_item, status: :created)
      author = create(:user)

      project_item.new_change(message: "update", author: author)
      project_item_change = project_item.project_item_changes.last

      expect(project_item_change.author).to eq(author)
    end
  end

  describe "#active?" do
    it "is true when processing is not done" do
      expect(build(:project_item, status: :created)).to be_active
      expect(build(:project_item, status: :registered)).to be_active
      expect(build(:project_item, status: :in_progress)).to be_active
    end

    it "is false when processing is done" do
      expect(build(:project_item, status: :ready)).to_not be_active
      expect(build(:project_item, status: :rejected)).to_not be_active
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
end
