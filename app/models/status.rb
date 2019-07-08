# frozen_string_literal: true

class Status < ApplicationRecord
  enum status: ProjectItem::STATUSES
  belongs_to :author,
             class_name: "User",
             optional: true
  belongs_to :pipeline, polymorphic: true

  validates :status, presence: true
end
