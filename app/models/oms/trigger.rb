# frozen_string_literal: true

class OMS::Trigger < ApplicationRecord
  belongs_to :oms, class_name: "OMS"

  enum method: {
    get: "get",
    post: "post",
    put: "put"
  }

  attribute :method, default: :post

  validates :url, presence: true
  validates :method, presence: true
end
