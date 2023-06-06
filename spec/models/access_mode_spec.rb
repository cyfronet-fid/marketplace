# frozen_string_literal: true

require "rails_helper"
require_relative "publishable"

RSpec.describe Vocabulary::AccessMode, backend: true do
  subject { Vocabulary::AccessMode.new(name: "Access Mode", description: "description", eid: "access_mode-am") }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:type) }
  it { should_not validate_presence_of(:eid) }
end
