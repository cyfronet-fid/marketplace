# frozen_string_literal: true

require "rails_helper"

RSpec.describe Vocabulary::Trl, backend: true do
  it { is_expected.to normalize(:eid).from(" ").to(nil) }
end
