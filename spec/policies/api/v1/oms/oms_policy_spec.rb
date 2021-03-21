# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::Oms::OmsPolicy do
  subject { described_class }

  permissions :show? do
    it "permits OMS admin", skip: "not yet implemented" do
      # TODO: Implement when doing authorization task
    end
  end
end
