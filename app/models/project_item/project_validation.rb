# frozen_string_literal: true

module ProjectItem::ProjectValidation
  extend ActiveSupport::Concern

  included do
    validates :project, presence: true
    validate :one_per_project, unless: :excluded?
  end

  private

  def one_per_project
    return if project.blank?

    offer_duplicated = project.project_items.reject { |pi| pi.parent.present? }.count { |pi| pi.offer.id == offer.id }

    errors.add(:project, :repeated_in_project) if offer_duplicated.positive?
  end

  def excluded?
    offer.blank? || offer.internal? || offer.bundle? || parent.present?
  end
end
