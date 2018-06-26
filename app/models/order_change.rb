# frozen_string_literal: true

class OrderChange < ApplicationRecord
  enum status: Order::STATUSES

  belongs_to :order
  belongs_to :author,
             class_name: "User",
             optional: true

  validates :status, presence: true, unless: :message
  validates :message, presence: true, unless: :status

  def question?
    author == order.user
  end
end
