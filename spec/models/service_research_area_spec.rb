# frozen_string_literal: true

require "rails_helper"

RSpec.describe ServiceResearchArea, type: :model do
  it { should belong_to(:service) }
  it { should belong_to(:research_area) }
  it { should validate_presence_of(:service) }
  it { should validate_presence_of(:research_area) }
end
