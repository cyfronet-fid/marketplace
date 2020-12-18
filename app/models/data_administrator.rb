# frozen_string_literal: true

class DataAdministrator < ApplicationRecord
  validates :first_name, :last_name, presence: true
  validates :email, presence: true, email: true
end
