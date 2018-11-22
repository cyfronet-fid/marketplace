# frozen_string_literal: true

class TargetGroup < ApplicationRecord
  has_many :service_target_groups, dependent: :destroy
  has_many :services, through: :service_target_groups
  has_many :service_categories, through: :services
  has_many :categories, through: :service_categories

  validates :name, presence: true
end
