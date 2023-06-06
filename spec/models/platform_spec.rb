# frozen_string_literal: true

require "rails_helper"
require_relative "publishable"

RSpec.describe Platform, type: :model, backend: true do
  include_examples "publishable"

  describe "validations" do
    it { should validate_presence_of(:name) }

    subject { create(:platform) }
    it { should validate_uniqueness_of(:name) }
  end
end
