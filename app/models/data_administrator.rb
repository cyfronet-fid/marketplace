# frozen_string_literal: true

class DataAdministrator < ApplicationRecord
  has_one :provider_data_administrator
  has_one :provider, through: :provider_data_administrator

  validates :first_name, :last_name, presence: true
  validates :email, presence: true, email: true
end
