# frozen_string_literal: true

require "rails_helper"

RSpec.describe Affiliation::Update do
  let(:user) { create(:user) }
  let(:affiliation) { create(:affiliation, user: user) }

  it "updates affiliation" do
    described_class.new(affiliation, organization: "new org").call

    expect(affiliation.organization).to eq("new org")
  end

  it "sends new confirmation email when email changed" do
    expect do
      described_class.
        new(affiliation, email: "prefix#{affiliation.email}").call
    end.to change { ActionMailer::Base.deliveries.count }.by(1)
  end

  it "does not send new confirmation email when email not changed" do
    expect { described_class.new(affiliation, organization: "new org").call }.
      to_not change { ActionMailer::Base.deliveries.count }
  end

  it "generates new token when email changes" do
    expect do
      described_class.
        new(affiliation, email: "prefix#{affiliation.email}").call
    end.to change { affiliation.token }
  end

  it "does not regenerate token when email not changed" do
    expect { described_class.new(affiliation, organization: "new org").call }.
      to_not change { affiliation.token }
  end
end
