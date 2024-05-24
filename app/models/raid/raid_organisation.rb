# frozen_string_literal: true

class Raid::RaidOrganisation < ApplicationRecord
  belongs_to :raid_project
  has_one :position, as: :positionable
  attr_accessor :position_attributes

  accepts_nested_attributes_for :position, allow_destroy: true

  validates :pid, presence: true
  validates :name, presence: true

  after_initialize :init_position

  protected

  def init_position
    return position if position
    build_position(position_attributes)
  end
end
