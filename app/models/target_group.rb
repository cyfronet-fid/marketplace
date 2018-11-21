# frozen_string_literal: true

class TargetGroup < ApplicationRecord
  has_many :service_target_groups, dependent: :destroy
  has_many :services, through: :service_target_groups

  validates :name, presence: true
end
