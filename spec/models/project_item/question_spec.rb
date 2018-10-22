# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProjectItem::Question do
  subject { ProjectItem::Question.new(text: "text", author: build(:user), project_item: build(:project_item)) }

  it { should validate_presence_of(:text).with_message("Question cannot be blank") }
  it { should validate_presence_of(:author) }
  it { should validate_presence_of(:project_item) }
end
