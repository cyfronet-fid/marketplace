# frozen_string_literal: true

class TargetUser < ApplicationRecord
  include Parentable
  include Publishable

  has_one_attached :logo

  has_many :service_target_users, dependent: :destroy
  has_many :services, through: :service_target_users
  has_many :bundle_target_users
  has_many :bundles, through: :bundle_target_users
  has_many :categorizations, through: :services
  has_many :categories, through: :categorizations

  validates :name, uniqueness: true, presence: true

  def to_s
    name
  end
end
