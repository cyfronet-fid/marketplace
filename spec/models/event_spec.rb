# frozen_string_literal: true

require "rails_helper"

RSpec.describe Event, type: :model do
  let(:project) { build(:project, id: 1) }

  it { should belong_to(:eventable) }
  it { should validate_presence_of(:action) }

  context "create event" do
    subject { Event.new(action: :create, eventable: project) }

    it { should_not validate_presence_of(:updates) }
    it { should be_valid }
  end

  context "update event" do
    subject { Event.new(action: :update,
                        eventable: project,
                        updates: [{ field: "name", before: "zxc", after: "qwe" }]) }

    it { should validate_presence_of(:updates) }
    it { should be_valid }

    context "#updates" do
      context "validation" do
        it "forbids empty" do
          subject.updates = []
          updates_not_valid!
        end

        it "forbids updates without field, before and after parameters" do
          subject.updates = [{ a: 1 }]
          updates_not_valid!
        end

        it "forbids non-string field parameter" do
          subject.updates = [{ field: 1, before: "a", after: "b" }]
          updates_not_valid!
        end

        it "allows non-string before and after parameters" do
          subject.updates = [{ field: "a", before: {}, after: { voucher_id: "1234" } }]
          expect(subject).to be_valid
        end

        def updates_not_valid!
          expect(subject).to_not be_valid
          expect(subject.errors[:updates].size).to eq(1)
        end
      end
    end
  end
end
