# frozen_string_literal: true

class ProviderDataAdministrator < ApplicationRecord
  belongs_to :provider
  belongs_to :data_administrator

  has_one :user, through: :data_administrator

  validates :provider, presence: true
  validates :data_administrator, presence: true
end
