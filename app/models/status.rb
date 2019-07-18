# frozen_string_literal: true

class Status < ApplicationRecord
  enum status: ProjectItem::STATUSES
  belongs_to :author,
             class_name: "User",
             optional: true
  belongs_to :status_holder, polymorphic: true

  validates :status, presence: true
end
