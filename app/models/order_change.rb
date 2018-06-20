# frozen_string_literal: true

class OrderChange < ApplicationRecord
  enum status: Order::STATUSES

  belongs_to :order, dependent: :destroy

  validates :status, presence: true, unless: :message
  validates :message, presence: true, unless: :status
end
