# frozen_string_literal: true

require "rails_helper"

RSpec.describe Order::QuestionPolicy do
  let(:user) { create(:user) }
  let(:question) { Order::Question.new(order: order) }

  subject { described_class }


  permissions :create? do
    context "with active order" do
      let(:order) { create(:order, user: user, status: :created) }

      it "grants access for order owner when order is active" do
        expect(subject).to permit(user, question)
      end

      it "denies access for others" do
        expect(subject).to_not permit(build(:user), question)
      end
    end

    context "with inactive order" do
      let(:order) { create(:order, user: user, status: :ready) }

      it "denies access even for order owner" do
        expect(subject).to_not permit(user, question)
      end
    end
  end
end
