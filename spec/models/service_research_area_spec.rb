# frozen_string_literal: true

require "rails_helper"

RSpec.describe ServiceScientificDomain, type: :model, backend: true do
  it { should belong_to(:service) }
  it { should belong_to(:scientific_domain) }
  it { should validate_presence_of(:service) }
  it { should validate_presence_of(:scientific_domain) }
end
