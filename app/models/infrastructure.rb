# frozen_string_literal: true

class Infrastructure < ApplicationRecord
  # States for infrastructure lifecycle
  STATES = %w[pending creating configured running failed destroyed].freeze

  belongs_to :project_item, autosave: false

  validates :im_base_url, presence: true
  validates :cloud_site, presence: true
  validates :state, presence: true, inclusion: { in: STATES }
  validates :im_infrastructure_id, uniqueness: true, allow_nil: true

  scope :active, -> { where.not(state: %w[destroyed failed]) }
  scope :pending_state_check,
        lambda { active.where("last_state_check_at IS NULL OR last_state_check_at < ?", 1.minute.ago) }

  # State predicates
  STATES.each { |state_name| define_method("#{state_name}?") { state == state_name } }

  def deployable_service
    project_item.offer.parent_service
  end

  def mark_created!(infrastructure_id)
    update_columns(im_infrastructure_id: infrastructure_id, state: "creating", last_state_check_at: Time.current)
  end

  def mark_configured!
    update_columns(state: "configured", last_state_check_at: Time.current)
  end

  def mark_running!(outputs_data = {})
    update_columns(state: "running", outputs: outputs_data, last_state_check_at: Time.current, last_error: nil)
  end

  def mark_failed!(error_message)
    update_columns(
      state: "failed",
      last_error: error_message,
      retry_count: retry_count + 1,
      last_state_check_at: Time.current
    )
  end

  def mark_destroyed!
    update_columns(state: "destroyed", last_state_check_at: Time.current)
  end

  def update_state_from_im!(im_state)
    case im_state&.downcase
    when "pending"
      update_columns(state: "creating", last_state_check_at: Time.current)
    when "configured"
      mark_configured!
    when "running", "stopped", "off"
      # "stopped"/"off" still considered running (infrastructure exists)
      update_columns(state: "running", last_state_check_at: Time.current)
    when "failed", "unconfigured"
      mark_failed!("Infrastructure Manager reported state: #{im_state}")
    else
      Rails.logger.warn "Unknown IM state '#{im_state}' for Infrastructure #{id}"
      update_columns(last_state_check_at: Time.current)
    end
  end

  def can_destroy?
    %w[creating configured running failed].include?(state) && im_infrastructure_id.present?
  end

  def deployment_url
    # outputs defaults to {} but add nil safety for defensive coding
    outputs&.dig("jupyterhub_url") || outputs&.dig("public_url") || outputs&.dig("endpoint")
  end
end
