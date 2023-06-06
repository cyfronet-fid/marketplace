# frozen_string_literal: true

require "rails_helper"

RSpec.describe LeadSection, type: :model, backend: true do
  it { should validate_presence_of(:title) }
  it { should have_many(:leads).dependent(:destroy) }
  it { should validate_presence_of(:slug) }
end
