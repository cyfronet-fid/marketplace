class Raid::RaidOrganisation < ApplicationRecord
  belongs_to :raid_project
  has_one :position, as: :positionable
  attr_accessor :position_attributes

  accepts_nested_attributes_for :position, allow_destroy: true

  validates :pid, presence: true

  after_initialize :init_position
  

  protected
  def init_position
    if position
      return position
    end
    build_position(position_attributes)
  end
end
