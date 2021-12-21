# frozen_string_literal: true

class Status < ApplicationRecord
  enum status_type: ProjectItem::STATUS_TYPES
  belongs_to :author, class_name: "User", optional: true
  belongs_to :status_holder, polymorphic: true

  validates :status, presence: true
  validates :status_type, presence: true
end
