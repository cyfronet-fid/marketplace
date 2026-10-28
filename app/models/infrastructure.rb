# frozen_string_literal: true

class Infrastructure < ApplicationRecord
  # States for infrastructure lifecycle
  STATES = %w[pending creating configured running failed destroyed].freeze

  belongs_to :project_item, autosave: false

  validates :api_base_url, presence: true
  validates :cloud_site, presence: true
  validates :state, presence: true, inclusion: { in: STATES }
  validates :deployment_id, uniqueness: true, allow_nil: true

  scope :active, -> { where.not(state: %w[destroyed failed]) }
  scope :adm_managed, -> { where.not(allocation_id: nil) }
  scope :pending_state_check,
        -> { active.adm_managed.where("last_state_check_at IS NULL OR last_state_check_at < ?", 1.minute.ago) }

  # State predicates, prefixed so state_destroyed? does not shadow ActiveRecord#destroyed?
  STATES.each { |state_name| define_method("state_#{state_name}?") { state == state_name } }

  def deployable_service
    project_item.offer.parent_service
  end

  def mark_created!(deployment_id)
    update!(deployment_id: deployment_id, state: "creating", last_state_check_at: Time.current)
  end

  def mark_creating!
    update!(state: "creating", last_state_check_at: Time.current)
  end

  def record_state_check!
    update!(last_state_check_at: Time.current)
  end

  def mark_configured!
    update!(state: "configured", last_state_check_at: Time.current)
  end

  def mark_running!(outputs_data = {})
    update!(state: "running", outputs: outputs_data, last_state_check_at: Time.current, last_error: nil)
  end

  def mark_failed!(error_message)
    update!(
      state: "failed",
      last_error: error_message,
      retry_count: retry_count + 1,
      last_state_check_at: Time.current
    )
  end

  def mark_destroyed!
    update!(state: "destroyed", last_state_check_at: Time.current)
  end

  def can_destroy?
    %w[creating configured running failed].include?(state) && deployment_id.present? && allocation_id.present?
  end

  def deployment_url
    Infrastructure::SelectDeploymentUrl.call(outputs, output_names)
  end
end
