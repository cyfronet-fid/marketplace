# frozen_string_literal: true

class TargetGroup < ApplicationRecord
  has_many :service_target_groups, dependent: :destroy
  has_many :services, through: :service_target_groups
  has_many :categorizations, through: :services
  has_many :categories, through: :categorizations

  validates :name, presence: true

  def to_s
    self.name
  end
end
