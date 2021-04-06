# frozen_string_literal: true

require "rails_helper"

RSpec.describe Event, type: :model do
  it { should belong_to(:eventable).optional }
  it { should validate_presence_of(:action) }
  it { should validate_presence_of(:additional_info) }

  context "additional info" do
    it "validates json scheme correctly" do
      expect(Event.new(action: :create, additional_info: { eventable_type: "Project", project_id: 1 })).to be_valid
      expect(Event.new(action: :create,
                       additional_info: { eventable_type: "ProjectItem", project_id: 1, project_item_id: 1 })).to be_valid
      expect(Event.new(action: :create,
                       additional_info: { eventable_type: "Message", project_id: 1, message_id: 1 })).to be_valid
      expect(Event.new(action: :create,
                       additional_info: { eventable_type: "Message", project_id: 1, project_item_id: 1, message_id: 1 })).to be_valid
      expect(Event.new(action: :create, additional_info: { eventable_type: "asd", project_id: 1 })).to_not be_valid
      expect(Event.new(action: :create, additional_info: { eventable_type: "Project" })).to_not be_valid
      expect(Event.new(action: :create, additional_info: {})).to_not be_valid
    end
  end

  context "create event" do
    subject { Event.new(action: :create,
                        eventable: build(:project, id: 1),
                        additional_info: { eventable_type: "Project", project_id: 1 }) }
    it { should_not validate_presence_of(:updates) }
    it { should be_valid }
  end

  context "update event" do
    subject { Event.new(action: :update,
                        updates: [{ field: "name", before: "zxc", after: "qwe" }],
                        additional_info: { eventable_type: "Project", project_id: 1 }) }
    it { should validate_presence_of(:updates) }
    it { should be_valid }

    it "should json scheme validate updates" do
      expect(Event.new(action: :update,
                       updates: [],
                       additional_info: { eventable_type: "Project", project_id: 1 })).to_not be_valid
      expect(Event.new(action: :update,
                       updates: [{ field: "name", before: "zxc", after: "qwe" }, { a: 1 }],
                       additional_info: { eventable_type: "Project", project_id: 1 })).to_not be_valid
    end
  end

  context "delete event" do
    subject { Event.new(action: :delete,
                        additional_info: { eventable_type: "Project", project_id: 1 }) }
    it { should_not validate_presence_of(:updates) }
    it { should_not belong_to(:eventable) }
    it { should be_valid }
  end
end
