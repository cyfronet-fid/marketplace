# frozen_string_literal: true

require "rails_helper"

RSpec.describe Affiliation::Confirm do
  let(:user) { create(:user) }

  it "confirms affiliation" do
    affiliation = create(:affiliation, user: user)
    confirmator = described_class.new(user, affiliation)

    result = confirmator.call

    affiliation.reload
    expect(result).to eq(:ok)
    expect(affiliation).to be_active
    expect(affiliation.token).to be_nil
  end

  it "denied to confirm affiliation does not belonging to other user" do
    affiliation = create(:affiliation, token: "secret")
    confirmator = described_class.new(user, affiliation)

    result = confirmator.call

    affiliation.reload
    expect(result).to eq(:not_owned)
    expect(affiliation).to be_created
  end

  it "do nothing when affiliation not found" do
    confirmator = described_class.new(user, nil)

    result = confirmator.call

    expect(result).to eq(:not_found)
  end
end
