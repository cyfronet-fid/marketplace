# frozen_string_literal: true

class TargetUser < ApplicationRecord
  include Parentable
  include Publishable

  # Edited through the vocabulary form, see Vocabulary#logo.
  has_one_attached :logo

  has_many :bundle_target_users
  has_many :bundles, through: :bundle_target_users

  validates :name, uniqueness: true, presence: true

  def to_s
    name
  end
end
