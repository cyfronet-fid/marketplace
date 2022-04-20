# frozen_string_literal: true

class Link < ApplicationRecord
  after_save { |record| record.destroy if record.url.blank? && record.name.blank? }

  belongs_to :linkable, polymorphic: true

  validate :name_without_url
  validates :type, presence: true

  private

  def name_without_url
    errors.add(:url, "can't be blank") if url.blank? && name.present?
  end
end
