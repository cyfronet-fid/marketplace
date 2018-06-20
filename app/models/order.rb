# frozen_string_literal: true

class Order < ApplicationRecord
  STATUSES = {
    created: "created",
    registered: "registered",
    in_progress: "in_progress",
    ready: "ready",
    rejected: "rejected"
  }

  enum status: STATUSES

  belongs_to :service
  belongs_to :user
  has_many :order_changes, dependent: :destroy

  validates :service, presence: true
  validates :user, presence: true
  validates :status, presence: true

  def new_change(new_status, message)
    order_changes.create(status: new_status, message: message)
    update_attributes(status: new_status)
  end
end
