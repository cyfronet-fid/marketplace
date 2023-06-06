# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::ProjectItemPolicy, type: :policy, backend: true do
  subject { described_class }

  let(:default_oms_admin) { create(:user) }
  let(:oms_admin) { create(:user) }

  let(:default_oms) { create(:default_oms, administrators: [default_oms_admin]) }
  let(:oms) { create(:oms, administrators: [oms_admin]) }

  let(:project1) { build(:project) }
  let(:project2) { build(:project) }

  let!(:project_item1) { create(:project_item, project: project1, offer: build(:offer, primary_oms: default_oms)) }
  let!(:project_item2) { create(:project_item, project: project1, offer: build(:offer, primary_oms: oms)) }
  let!(:project_item3) { create(:project_item, project: project2, offer: build(:offer, primary_oms: default_oms)) }
  let!(:project_item4) { create(:project_item, project: project2, offer: build(:offer, primary_oms: nil)) }

  permissions ".scope" do
    it "shows all project items when user is a default oms admin" do
      expect(subject::Scope.new(default_oms_admin, project1.project_items).resolve).to contain_exactly(
        project_item1,
        project_item2
      )
    end

    it "shows project_items which offers' primary_oms is administered by user" do
      expect(subject::Scope.new(default_oms_admin, project2.project_items).resolve).to contain_exactly(
        project_item3,
        project_item4
      )
      expect(subject::Scope.new(oms_admin, project1.project_items).resolve).to contain_exactly(project_item2)
      expect(subject::Scope.new(oms_admin, project2.project_items).resolve).to eq([])
    end
  end

  permissions :show? do
    it "grants permission to project_item administrated by user and default_oms admin" do
      expect(subject).to permit(default_oms_admin, project_item1)
      expect(subject).to permit(default_oms_admin, project_item2)
      expect(subject).to permit(default_oms_admin, project_item3)
      expect(subject).to permit(default_oms_admin, project_item4)

      expect(subject).to_not permit(oms_admin, project_item1)
      expect(subject).to permit(oms_admin, project_item2)
      expect(subject).to_not permit(oms_admin, project_item3)
      expect(subject).to_not permit(oms_admin, project_item4)
    end
  end

  permissions :update? do
    it "grants permission to project_item administrated by user" do
      expect(subject).to permit(default_oms_admin, project_item1)
      expect(subject).to_not permit(default_oms_admin, project_item2)
      expect(subject).to permit(default_oms_admin, project_item3)
      expect(subject).to permit(default_oms_admin, project_item4)

      expect(subject).to_not permit(oms_admin, project_item1)
      expect(subject).to permit(oms_admin, project_item2)
      expect(subject).to_not permit(oms_admin, project_item4)
      expect(subject).to_not permit(oms_admin, project_item4)
    end
  end
end
