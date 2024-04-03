# frozen_string_literal: true

class Raid::Contributor < ApplicationRecord

  belongs_to :raid_project
  has_one :position, dependent: :destroy
  attr_accessor :position_attributes

  accepts_nested_attributes_for :position, allow_destroy: true
  
  PID_TYPES = { ORCID: "https://orcid.org/", ISNI: "https://isni.org/" }.freeze
  
  enum pid_type: PID_TYPES

  validates :pid, presence: true
  validates :pid_type, presence: true

  after_initialize :init_position
  

  protected
  def init_position
    position ||= build_position(position_attributes)
  end
end
