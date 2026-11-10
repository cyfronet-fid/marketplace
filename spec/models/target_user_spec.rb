# frozen_string_literal: true

require "rails_helper"
require_relative "publishable"

RSpec.describe TargetUser, :backend, type: :model do
  include_examples "publishable"

  it { is_expected.to validate_presence_of(:name) }

  it { is_expected.to normalize(:eid).from(" ").to(nil) }
end
