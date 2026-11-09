# frozen_string_literal: true

require "rails_helper"

RSpec.describe ViewStatistic do
  it { is_expected.to belong_to(:viewable) }
end
