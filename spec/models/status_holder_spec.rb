# frozen_string_literal: true

shared_examples "status_holder" do
  it { is_expected.to have_many(:statuses) }
end
