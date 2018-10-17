# frozen_string_literal: true

require "rails_helper"

RSpec.describe Affiliation::Confirm do
  let(:user) { create(:user) }

  it "confirms affiliation" do
    affiliation = create(:affiliation, token: "secret", user: user)

    result = described_class.new(user, "secret").call
    affiliation.reload

    expect(result).to be_truthy
    expect(affiliation).to be_active
    expect(affiliation.token).to be_nil
  end

  it "denied to confirm affiliation does not belonging to other user" do
    affiliation = create(:affiliation, token: "secret")
    confirmator = described_class.new(user, "secret")

    result = confirmator.call
    affiliation.reload

    expect(result).to be_falsy
    expect(affiliation).to be_created
    expect(confirmator.error).to include "not belong to you"
  end

  it "do nothing when affiliation not found" do
    confirmator = described_class.new(user, "secret")

    result = confirmator.call

    expect(result).to be_falsy
    expect(confirmator.error).to include "cannot be found"
  end
end
