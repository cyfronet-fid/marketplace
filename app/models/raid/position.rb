# frozen_string_literal: true

class Raid::Position < ApplicationRecord
  belongs_to :contributor
  include DateValidation

  PID = {
    principal_investigator: "principal-investigator",
    co_investigator: "co-investigator",
    other_participant: "other-participant"
  }.freeze
  
  enum pid: PID
  validates :pid, presence: true
end
