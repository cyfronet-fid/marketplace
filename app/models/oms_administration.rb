# frozen_string_literal: true

class OmsAdministration < ApplicationRecord
  belongs_to :oms
  belongs_to :user

  validates :oms, presence: true
  validates :user, presence: true
end
