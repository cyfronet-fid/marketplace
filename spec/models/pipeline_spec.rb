# frozen_string_literal: true

shared_examples "pipeline" do
  it { is_expected.to have_many(:statuses) }
end
