# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::ProjectPolicy, type: :policy, backend: true do
  subject { described_class }

  let(:default_oms_admin) { create(:user) }
  let(:oms_admin) { create(:user) }

  let(:default_oms) { create(:default_oms, administrators: [default_oms_admin]) }
  let(:oms) { create(:oms, administrators: [oms_admin]) }

  let!(:project1) do
    create(
      :project,
      project_items: [
        build(:project_item, offer: build(:offer, primary_oms: oms)),
        build(:project_item, offer: build(:offer, primary_oms: default_oms))
      ]
    )
  end
  let!(:project2) { create(:project, project_items: [build(:project_item, offer: build(:offer, primary_oms: nil))]) }
  let!(:project3) { create(:project, project_items: [build(:project_item, offer: build(:offer, primary_oms: oms))]) }

  permissions ".scope" do
    it "shows all projects when user is a default oms admin" do
      expect(subject::Scope.new(default_oms_admin, default_oms.projects).resolve).to contain_exactly(
        project1,
        project2,
        project3
      )

      # Shouldn't happen because we are authorizing if a user is administrating a particular OMS beforehand
      expect(subject::Scope.new(default_oms_admin, oms.projects).resolve).to contain_exactly(project1, project3)
    end

    it "shows projects which offers' primary_oms is administrated by user" do
      expect(subject::Scope.new(oms_admin, oms.projects).resolve).to contain_exactly(project1, project3)

      # Shouldn't happen because we are authorizing if a user is administrating a particular OMS beforehand
      expect(subject::Scope.new(oms_admin, default_oms.projects).resolve).to contain_exactly(project1, project3)
    end
  end

  permissions :show? do
    it "grants permission to project administrated by user or a default oms admin" do
      expect(subject).to permit(default_oms_admin, project1)
      expect(subject).to permit(default_oms_admin, project2)
      expect(subject).to permit(default_oms_admin, project3)

      expect(subject).to permit(oms_admin, project1)
      expect(subject).to_not permit(oms_admin, project2)
      expect(subject).to permit(oms_admin, project3)
    end
  end
end
