# frozen_string_literal: true

class Order < ApplicationRecord
  has_one :service
  belongs_to :user

  validates :service, presence: true
  validates :user, presence: true
end
