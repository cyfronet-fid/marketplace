# frozen_string_literal: true

require "rails_helper"

RSpec.describe MessagePolicy, type: :policy, backend: true do
  let(:user) { create(:user) }

  subject { described_class }

  def resolve
    subject::Scope.new(user, Message).resolve
  end

  permissions ".scope" do
    it "allows scope=public" do
      message = create(:message, scope: :public)

      expect(resolve).to contain_exactly(message)
    end

    it "allows scope=user_direct" do
      message = create(:message, scope: :user_direct)

      expect(resolve).to contain_exactly(message)
    end

    it "forbids scope=internal" do
      create(:message, scope: :internal)

      expect(resolve).to be_empty
    end
  end

  context "permitted_attributes" do
    it "should return message" do
      policy = described_class.new(user, create(:message))
      expect(policy.permitted_attributes).to match_array([:message])
    end
  end
end
