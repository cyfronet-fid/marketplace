# frozen_string_literal: true

require "rails_helper"

RSpec.describe FundingBody do
  subject { FundingBody.new(name: "Funding Body", description: "Poland", eid: "funding_body-fb") }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:type) }
  it { should validate_presence_of(:eid) }
end
