# frozen_string_literal: true

require "rails_helper"

RSpec.describe Event, type: :model, backend: true do
  it { should belong_to(:eventable) }
  it { should validate_presence_of(:action) }

  context "create event" do
    subject { create(:event) }

    it { should_not validate_presence_of(:updates) }
    it { should be_valid }
  end

  context "update event" do
    subject { build(:event, action: :update, updates: [{ field: "name", before: "zxc", after: "qwe" }]) }

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

  context "#omses" do
    subject { build(:event) }

    it "handles empty" do
      allow(subject.eventable).to receive(:eventable_omses).and_return([])

      expect(subject.omses).to eq([])
    end

    it "handles list" do
      omses = create_pair(:oms)
      allow(subject.eventable).to receive(:eventable_omses).and_return(omses)

      expect(subject.omses).to eq(omses)
    end

    context "with default OMS" do
      let!(:default_oms) { create(:default_oms) }

      it "handles empty" do
        allow(subject.eventable).to receive(:eventable_omses).and_return([])

        expect(subject.omses).to eq([default_oms])
      end

      it "handles list" do
        omses = create_pair(:oms)
        allow(subject.eventable).to receive(:eventable_omses).and_return(omses)

        expect(subject.omses).to eq(omses.push(default_oms))
      end

      it "doesn't duplicate default_oms" do
        oms = create(:oms)
        allow(subject.eventable).to receive(:eventable_omses).and_return([oms, default_oms])

        expect(subject.omses).to contain_exactly(oms, default_oms)
      end
    end
  end

  context "#after_commit" do
    it "calls Event::CallTriggers" do
      allow(Faraday).to receive(:post)

      event = build(:event)
      allow(event).to receive(:omses).and_return(
        %w[url1 url2].map { |trigger_url| create(:oms, trigger: build(:trigger, url: trigger_url)) }
      )

      assert_performed_jobs(2, only: OMS::CallTriggerJob, queue: :orders) { event.save! }

      expect(Faraday).to have_received(:post).with("url1")
      expect(Faraday).to have_received(:post).with("url2")
    end
  end
end
