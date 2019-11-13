# frozen_string_literal: true

module ProjectItem::ProjectValidation
  extend ActiveSupport::Concern

  included do
    validates :project, presence: true
    validate :one_per_project, unless: :properties?
  end

  def one_per_project
    project_items_services = Service.joins(offers: { project_items: :project })
      .where(id: offer&.service_id, offers: { project_items: { project_id: [ project_id] } })
      .where.not(offers: { project_items: { id: id } })
      .count.positive?

    errors.add(:project, :repited_in_project, message: "^You cannot add open access service #{service.title} to project #{project.name} twice") unless !project_items_services.present?
  end
end
