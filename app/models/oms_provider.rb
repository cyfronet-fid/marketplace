# frozen_string_literal: true

class OmsProvider < ApplicationRecord
  belongs_to :oms
  belongs_to :provider

  validates :oms, presence: true
  validates :provider, presence: true
end
