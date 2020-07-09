# frozen_string_literal: true

require "rails_helper"

RSpec.describe AccessMode do
  subject { AccessMode.new(name: "Access Mode", description: "description", eid: "access_mode-am") }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:type) }
  it { should validate_presence_of(:eid) }
end
