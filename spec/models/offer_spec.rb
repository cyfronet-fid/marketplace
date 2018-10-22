# frozen_string_literal: true

require "rails_helper"

RSpec.describe Offer do
  it { should validate_presence_of(:title) }
  it { should validate_presence_of(:description) }
  it { should validate_presence_of(:service) }

  it { should belong_to(:service) }

  it { should have_many(:project_items).dependent(:restrict_with_error) }
end
