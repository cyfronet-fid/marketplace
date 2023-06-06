# frozen_string_literal: true

require "rails_helper"

RSpec.describe Vocabulary::FundingBody, backend: true do
  subject { Vocabulary::FundingBody.new(name: "Funding Body", description: "Poland", eid: "funding_body-fb") }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:type) }
  it { should_not validate_presence_of(:eid) }
end
