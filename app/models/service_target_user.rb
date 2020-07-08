# frozen_string_literal: true

class ServiceTargetUser < ApplicationRecord
  belongs_to :service
  belongs_to :target_user

  validates :service, presence: true
  validates :target_user, presence: true, uniqueness: { scope: :service_id }
end
