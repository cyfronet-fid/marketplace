# frozen_string_literal: true

require "rails_helper"

RSpec.describe ServiceArea, type: :model do
  it { should belong_to(:service) }
  it { should belong_to(:area) }
end
