# frozen_string_literal: true

class Lead < ApplicationRecord
  has_one_attached :picture
  belongs_to :lead_section

  delegate :template, to: :lead_section

  validates :url, mp_url: true
  validates :url, presence: true
  validates :header, presence: true
  validates :body, presence: true
  validates :picture, blob: { content_type: :image }
  # validates :picture, presence: true
  validate :picture_variable?, on: %i[create update]

  private

  def picture_variable?
    picture.variable? if picture.present?
  end
end
