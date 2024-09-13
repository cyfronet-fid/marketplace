# frozen_string_literal: true

module Statusable
  extend ActiveSupport::Concern

  included do
    enum :status, STATUSES

    scope :visible, -> { where(status: VISIBLE_STATUSES) }
    scope :active, -> { where(status: PUBLIC_STATUSES) }
    scope :associable, -> { where.not(status: INVISIBLE_STATUSES) }

    validates :status, presence: true, inclusion: { in: STATUSES.values }
  end

  STATUSES = {
    published: "published",
    suspended: "suspended",
    unpublished: "unpublished",
    draft: "draft",
    errored: "errored",
    deleted: "deleted"
  }.freeze

  PUBLIC_STATUSES = %w[published errored].freeze
  VISIBLE_STATUSES = %w[published suspended errored].freeze
  INVISIBLE_STATUSES = %w[deleted].freeze
  HIDEABLE_STATUSES = %w[suspended deleted].freeze
  MANAGEABLE_STATUSES = (STATUSES.values - INVISIBLE_STATUSES).freeze

  def public?
    PUBLIC_STATUSES.include?(status)
  end
end
