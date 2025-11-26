# frozen_string_literal: true

class UserFavourite < ApplicationRecord
  belongs_to :user
  belongs_to :favoritable, polymorphic: true

  validates :user, presence: true, uniqueness: { scope: %i[favoritable_type favoritable_id] }
  validates :favoritable_id, presence: true
  validates :favoritable_type, presence: true
end
