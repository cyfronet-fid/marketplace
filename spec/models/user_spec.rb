# frozen_string_literal: true

require "rails_helper"

RSpec.describe User do
  it { should validate_presence_of(:first_name) }
  it { should validate_presence_of(:last_name) }
  it { should validate_presence_of(:email) }
  it { should validate_presence_of(:uid) }

  it { should have_many(:projects).dependent(:destroy) }
  it { should have_many(:affiliations).dependent(:destroy) }

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

    it "stores counter cache" do
      user = create(:user)
      _active_affiliation = create(:affiliation, status: :active, user: user)
      _created__affiliation = create(:affiliation, status: :created, user: user)

      user.reload

      expect(user.active_affiliations_count).to eq(1)
    end

    it "updates counter cache when state updated" do
      user = create(:user)
      affiliation = create(:affiliation, status: :created, user: user)

      affiliation.update(status: :active)
      user.reload

      expect(user.active_affiliations_count).to eq(1)

    end
  end

  context "#active_affiliation?" do
    it "is true when there is active affiliation" do
      user = create(:user)
      _active_affiliation = create(:affiliation, status: :active, user: user)

      user.reload

      expect(user).to be_active_affiliation
    end

    it "is false when there are other than active affiliations" do
      user = create(:user)
      _created__affiliation = create(:affiliation, status: :created, user: user)

      user.reload

      expect(user).to_not be_active_affiliation
    end
  end
end
