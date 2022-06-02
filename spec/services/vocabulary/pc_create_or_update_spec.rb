# frozen_string_literal: true

require "rails_helper"

RSpec.describe Vocabulary::PcCreateOrUpdate do
  let(:vocabulary_eid) { "target_user-researchers" }

  before(:each) do
    vocabulary_response = double(status: 200, body: create(:jms_vocabulary, eid: vocabulary_eid))
    allow_any_instance_of(Importers::Request).to receive(:call).and_return(vocabulary_response)
  end

  describe "#succesfull responses" do
    it "should create new vocabulary" do
      vocabulary = create(:jms_vocabulary, eid: "target_user-test", name: "Test Purposes")
      expect { stub_described_class(vocabulary) }.to change { TargetUser.count }.by(1)

      vocabulary = TargetUser.last

      expect(vocabulary.name).to eq("Test Purposes")
      expect(vocabulary.description).to eq("Test")
      expect(vocabulary.eid).to eq("target_user-test")
    end
  end

  private

  def stub_described_class(vocabulary)
    described_service = Vocabulary::PcCreateOrUpdate.new(vocabulary)

    allow(described_service).to receive(:open)
    described_service.call
  end
end
