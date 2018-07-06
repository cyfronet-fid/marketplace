# frozen_string_literal: true

require "rails_helper"

RSpec.describe Affiliation do
  subject { create(:affiliation) }

  it { should validate_numericality_of(:iid) }
  it { should validate_presence_of(:iid) }
  it { should validate_presence_of(:organization) }
  it { should validate_presence_of(:email) }
  it { should validate_presence_of(:webpage) }
  it { should validate_presence_of(:status) }

  it { should belong_to(:user) }

  it "is valid when email is from webpage domain" do
    affiliation = build(:affiliation,
                        email: "jonhdoe@uni.edu",
                        webpage: "http://my.uni.edu")

    expect(affiliation).to be_valid
  end

  it "is invalid when email is from different domain than webpage" do
    affiliation = build(:affiliation,
                        email: "jonhdoe@uni.edu",
                        webpage: "http://my.duni.edu")

    expect(affiliation).to_not be_valid
    expect(affiliation.errors[:email]).to_not be_blank
  end

  it "finds affiliation by token" do
    affiliation = create(:affiliation, token: "secret")

    expect(Affiliation.find_by_token("secret")).to eq affiliation
  end

  it "does not find affiliation with empty token" do
    create(:affiliation, token: nil)

    expect(Affiliation.find_by_token(nil)).to be_nil
    expect(Affiliation.find_by_token("")).to be_nil
    expect(Affiliation.find_by_token("  ")).to be_nil
  end
end
