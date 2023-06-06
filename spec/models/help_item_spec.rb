# frozen_string_literal: true

require "rails_helper"

RSpec.describe HelpItem, type: :model, backend: true do
  it { should validate_presence_of(:title) }
  it { should validate_presence_of(:content) }
  it { should belong_to(:help_section) }
end
