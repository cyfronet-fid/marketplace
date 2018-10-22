# frozen_string_literal: true

FactoryBot.define do
  factory :question, class: ProjectItem::Question do
    sequence(:text) { |n| "question #{n} message" }
    project_item
    to_create { |instance| ProjectItem::Question::Create.new(instance) }
  end
end
