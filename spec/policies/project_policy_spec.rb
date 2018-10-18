# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectPolicy do
  let(:user) { create(:user) }

  subject { described_class }


  it "returns only user projects" do
    owned_project = create(:project, user: user)
    _other_user_project = create(:project)

    scope = described_class::Scope.new(user, Project)

    expect(scope.resolve).to contain_exactly(owned_project)
  end
end
