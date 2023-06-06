# frozen_string_literal: true

require "rails_helper"
require_relative "publishable"

RSpec.describe TargetUser, type: :model, backend: true do
  include_examples "publishable"

  it { should validate_presence_of(:name) }
end
