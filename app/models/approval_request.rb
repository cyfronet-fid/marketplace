# frozen_string_literal: true

class ApprovalRequest < ApplicationRecord
  include Messageable
  include Statusable

  attr_accessor :current_action, :message

  enum :last_action, { accepted: "Accept", requested_for_changes: "Request for completion", rejected: "Reject" }.freeze

  scope :active, -> { where.not(status: :deleted) }
  scope :inactive, -> { where(status: :deleted) }

  before_update :update_last_action

  belongs_to :user
  belongs_to :approvable, polymorphic: true
  belongs_to :provider, -> { where(approvable_type: "Provider") }, foreign_key: "approvable_id", optional: true

  validates :current_action, presence: true, on: :update, if: -> { message.blank? }
  validates :last_action, presence: true, inclusion: { in: last_actions }, on: :update, if: -> { message.blank? }
  validates :message, presence: true, on: :update, if: -> { current_action == "requested_for_changes" }
  validates :provider_id, presence: true

  def provider_id=(value)
    self.approvable_id = value
  end

  def provider_id
    approvable_type == "Provider" ? approvable_id : nil
  end

  def eventable_omses
    []
  end

  def update_last_action
    self.last_action = current_action
  end
end
