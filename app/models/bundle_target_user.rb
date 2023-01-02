# frozen_string_literal: true

class BundleTargetUser < ApplicationRecord
  belongs_to :bundle
  belongs_to :target_user

  validates :bundle, presence: true
  validates :target_user, presence: true
end
