# frozen_string_literal: true

require "rails_helper"

RSpec.describe AccessType do
  subject { FundingBody.new(name: "AccessType", description: "description", eid: "access_type-at") }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:type) }
  it { should validate_presence_of(:eid) }
end
