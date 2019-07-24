# frozen_string_literal: true

shared_examples "messageable" do
  it { is_expected.to have_many(:messages) }
end
