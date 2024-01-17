# frozen_string_literal: true

module Statusable
  extend ActiveSupport::Concern

  included do
    enum status: STATUSES

    validates :status, presence: true, inclusion: { in: STATUSES.values }
  end

  STATUSES = {
    published: "published",
    unverified: "unverified",
    suspended: "suspended",
    unpublished: "unpublished",
    draft: "draft",
    errored: "errored",
    deleted: "deleted"
  }.freeze

  PUBLIC_STATUSES = %w[published unverified errored].freeze
  VISIBLE_STATUSES = %w[published unverified suspended errored].freeze
end
