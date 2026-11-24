# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::StatisticsPolicy, type: :policy do
  subject(:policy) { described_class }

  permissions :index?, :show? do
    it("grants a user without a role") { is_expected.to permit(build(:user), Service) }
    it("denies without a user") { is_expected.not_to permit(nil, Service) }
  end

  describe Api::V1::StatisticsPolicy::Scope do
    subject(:visible_ids) { described_class.new(build(:user), Service).resolve.ids }

    let!(:visible) do
      [create(:service, status: :published), create(:service, status: :errored), create(:datasource)]
    end

    before { %i[draft unpublished suspended deleted].each { |status| create(:service, status:) } }

    it "holds the published and errored Services, Datasources included" do
      expect(visible_ids).to match_array(visible.map(&:id))
    end
  end
end
