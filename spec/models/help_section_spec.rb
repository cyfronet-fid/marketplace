# frozen_string_literal: true

require "rails_helper"

RSpec.describe HelpSection do
  it { should validate_presence_of(:title) }
  it { should have_many(:help_items).dependent(:destroy) }
end
