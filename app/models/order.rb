# frozen_string_literal: true

class Order < ApplicationRecord
  enum status: {
    # cannot name it new, because it will try to generate
    # new method, which is already defined
    new_order: "new",
    in_progress: "in_progress",
    ready: "ready",
    rejected: "rejected"
  }

  belongs_to :service
  belongs_to :user

  validates :service, presence: true
  validates :user, presence: true
  validates :status, presence: true
end
