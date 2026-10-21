# frozen_string_literal: true

require "rails_helper"

RSpec.describe Infrastructure::StatePollingJob, type: :job do
  before { allow(Infrastructure::RefreshState).to receive(:call) }

  describe "polling a single infrastructure" do
    context "with an active ADM infrastructure" do
      let(:infrastructure) { create(:infrastructure, :creating) }

      it "refreshes its state" do
        described_class.perform_now(infrastructure.id)
        expect(Infrastructure::RefreshState).to have_received(:call).with(infrastructure, client: anything)
      end
    end

    %i[failed destroyed].each do |state|
      context "with a #{state} infrastructure" do
        let(:infrastructure) { create(:infrastructure, state) }

        it "does nothing" do
          described_class.perform_now(infrastructure.id)
          expect(Infrastructure::RefreshState).not_to have_received(:call)
        end
      end
    end

    context "with a legacy Infrastructure Manager infrastructure" do
      let(:infrastructure) { create(:infrastructure, :creating, allocation_id: nil) }

      it "does nothing" do
        described_class.perform_now(infrastructure.id)
        expect(Infrastructure::RefreshState).not_to have_received(:call)
      end
    end

    context "with an unknown infrastructure" do
      it "does nothing" do
        described_class.perform_now(0)
        expect(Infrastructure::RefreshState).not_to have_received(:call)
      end
    end
  end

  describe "polling all pending infrastructures" do
    let!(:due) { create(:infrastructure, :running, last_state_check_at: 2.minutes.ago) }
    let!(:recently_checked) { create(:infrastructure, :running, last_state_check_at: 10.seconds.ago) }
    let!(:not_deployed_yet) { create(:infrastructure, allocation_id: "alloc-1") }

    it "refreshes the infrastructures due for a state check" do
      described_class.perform_now
      expect(Infrastructure::RefreshState).to have_received(:call).once.with(due, client: anything)
    end

    it "skips recently checked and not yet deployed infrastructures" do
      described_class.perform_now
      expect(Infrastructure::RefreshState).not_to have_received(:call).with(
        satisfy { |infra| [recently_checked, not_deployed_yet].include?(infra) },
        anything
      )
    end
  end

  describe "the ADM client used for polling" do
    let(:clients) { [] }

    before do
      create_list(:infrastructure, 2, :running, last_state_check_at: 2.minutes.ago)
      allow(Infrastructure::RefreshState).to receive(:call) { |_infrastructure, client:| clients << client }
      described_class.perform_now
    end

    it "is shared between the infrastructures" do
      expect(clients).to contain_exactly(an_instance_of(Adm::Client), equal(clients.first))
    end
  end

  describe "errors while polling all pending infrastructures" do
    let!(:broken) { create(:infrastructure, :running, last_state_check_at: 2.minutes.ago) }
    let!(:healthy) { create(:infrastructure, :running, last_state_check_at: 3.minutes.ago) }

    before do
      allow(Infrastructure::RefreshState).to receive(:call).with(broken, client: anything).and_raise(
        Adm::Error,
        "ADM request failed: 503"
      )
      described_class.perform_now
    end

    it "keeps polling the other infrastructures" do
      expect(Infrastructure::RefreshState).to have_received(:call).with(healthy, client: anything)
    end

    it "records the state check of the failed one" do
      expect(broken.reload.last_state_check_at).to be_within(5.seconds).of(Time.current)
    end
  end

  it "uses the default queue" do
    expect(described_class.new.queue_name).to eq("default")
  end
end
