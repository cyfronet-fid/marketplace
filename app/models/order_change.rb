# frozen_string_literal: true

class OrderChange < ApplicationRecord
  enum status: ProjectItem::STATUSES

  belongs_to :project_item
  belongs_to :author,
             class_name: "User",
             optional: true

  validates :status, presence: true, unless: :message
  validates :message, presence: true, unless: :status

  def question?
    author == project_item.user
  end
end
