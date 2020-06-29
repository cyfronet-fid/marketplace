# frozen_string_literal: true

class UserScientificDomain < ApplicationRecord
  belongs_to :user
  belongs_to :scientific_domain

  validates :user, presence: true
  validates :scientific_domain, presence: true, uniqueness: { scope: :user_id }
end
