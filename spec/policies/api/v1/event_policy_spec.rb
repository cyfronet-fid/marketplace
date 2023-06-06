# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::EventPolicy, type: :policy, backend: true do
  subject { described_class }

  permissions ".scope" do
    let(:default_oms_admin) { create(:user) }
    let(:other_oms_admin) { create(:user) }

    let(:default_oms) { create(:default_oms, administrators: [default_oms_admin]) }
    let(:other_oms) { create(:oms, administrators: [other_oms_admin]) }

    let(:project_item1) { build(:project_item, offer: build(:offer, primary_oms: default_oms), iid: 1) }
    let(:project_item2) { build(:project_item, offer: build(:offer, primary_oms: other_oms), iid: 2) }
    let(:project_item3) { build(:project_item, offer: build(:offer, primary_oms: nil), iid: 1) }

    let!(:project1) { create(:project, project_items: [project_item1, project_item2]) }
    let!(:project2) { create(:project, project_items: [project_item3]) }

    let!(:message1) { create(:message, messageable: project1) }
    let!(:message2) { create(:message, messageable: project2) }
    let!(:message3) { create(:message, messageable: project2) }

    let!(:message4) { create(:message, messageable: project_item1) }
    let!(:message5) { create(:message, messageable: project_item2) }
    let!(:message6) { create(:message, messageable: project_item3) }
    let!(:message7) { create(:message, messageable: project_item1) }

    it "shows all events for a default oms" do
      expect(subject::Scope.new(default_oms_admin, default_oms.events).resolve.count).to eq(12)
      expect(subject::Scope.new(default_oms_admin, default_oms.events).resolve.map(&:eventable)).to contain_exactly(
        project_item1,
        project_item2,
        project_item3,
        project1,
        project2,
        message1,
        message2,
        message3,
        message4,
        message5,
        message6,
        message7
      )

      # Shouldn't happen because we are authorizing if a user is administrating a particular OMS beforehand
      expect(subject::Scope.new(default_oms_admin, other_oms.events).resolve.count).to eq(4)
      expect(subject::Scope.new(default_oms_admin, other_oms.events).resolve.map(&:eventable)).to contain_exactly(
        project_item2,
        project1,
        message1,
        message5
      )
    end

    it "shows events which offers' primary_oms is administrated by user" do
      expect(subject::Scope.new(other_oms_admin, other_oms.events).resolve.count).to eq(4)
      expect(subject::Scope.new(other_oms_admin, other_oms.events).resolve.map(&:eventable)).to contain_exactly(
        project_item2,
        project1,
        message1,
        message5
      )

      # Shouldn't happen because we are authorizing if a user is administrating a particular OMS beforehand
      expect(subject::Scope.new(other_oms_admin, default_oms.events).resolve.count).to eq(4)
      expect(subject::Scope.new(other_oms_admin, default_oms.events).resolve.map(&:eventable)).to contain_exactly(
        project_item2,
        project1,
        message1,
        message5
      )
    end
  end
end
