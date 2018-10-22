# frozen_string_literal: true

require "rails_helper"

RSpec.describe Offer do
  it { should validate_presence_of(:title) }
  it { should validate_presence_of(:description) }

  it { should belong_to(:service) }
end
