# frozen_string_literal: true

require "rails_helper"

RSpec.describe Affiliation::Create do
  let(:user) { create(:user) }

  it "saves valid affiliation in db" do
    affiliation = described_class.new(build(:affiliation, user: user)).call

    expect(affiliation).to be_persisted
  end

  it "generates affiliation token" do
    affiliation = described_class.new(build(:affiliation, user: user)).call

    expect(affiliation.token).to_not be_blank
  end

  it "sends confirmation email to affiliation owner" do
    expect { described_class.new(build(:affiliation, user: user)).call }.
      to change { ActionMailer::Base.deliveries.count }.by(1)
  end
end
