# frozen_string_literal: true

class Platform < ApplicationRecord
  include Publishable

  include Parentable

  has_many :service_related_platforms, dependent: :destroy
  has_many :services, through: :service_related_platforms
  has_many :categorizations, through: :services
  has_many :categories, through: :categorizations

  validates :name, presence: true, uniqueness: true

  def to_s
    name
  end
end
