# frozen_string_literal: true

class UserCategory < ApplicationRecord
  belongs_to :user
  belongs_to :category

  validates :user, presence: true
  validates :category, presence: true, uniqueness: { scope: :user_id }
end
