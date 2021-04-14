# frozen_string_literal: true

class UserService < ApplicationRecord
  belongs_to :user
  belongs_to :service

  validates :user, presence: true, uniqueness: { scope: :service_id }
  validates :service, presence: true
end
