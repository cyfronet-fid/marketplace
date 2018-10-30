# frozen_string_literal: true

require "rails_helper"

RSpec.describe User do
  it { should validate_presence_of(:first_name) }
  it { should validate_presence_of(:last_name) }
  it { should validate_presence_of(:email) }
  it { should validate_presence_of(:uid) }

  it { should have_many(:projects).dependent(:destroy) }
  it { should have_many(:affiliations).dependent(:destroy) }
  it { should have_many(:owned_services).dependent(:nullify) }

  context "#full_name" do
    it "is composed from first and last name" do
      user = build(:user, first_name: "John", last_name: "Rambo")

      expect(user.full_name).to eq "John Rambo"
    end
  end

  context "#active_affiliations" do
    it "returns only affiliation with active status" do
      user = create(:user)
      active_affiliation = create(:affiliation, status: :active, user: user)
      _created__affiliation = create(:affiliation, status: :created, user: user)

      expect(user.active_affiliations).to contain_exactly(active_affiliation)
    end
  end
end
