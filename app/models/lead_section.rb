# frozen_string_literal: true

class LeadSection < ApplicationRecord
  extend FriendlyId
  TEMPLATES = { learn_more: "learn_more", use_case: "use_case" }.freeze

  enum :template, TEMPLATES
  friendly_id :title, use: :slugged
  has_many :leads, -> { order(:position) }, dependent: :destroy

  validates :title, presence: true
  validates :slug, presence: true
  validates :slug, uniqueness: true
end
