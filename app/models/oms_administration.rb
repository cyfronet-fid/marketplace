# frozen_string_literal: true

class OMSAdministration < ApplicationRecord
  belongs_to :oms
  belongs_to :user

  validates :oms, presence: true
  validates :user, presence: true
end
