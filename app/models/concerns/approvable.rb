# frozen_string_literal: true

module Approvable
  extend ActiveSupport::Concern

  included { has_many :approval_requests, as: :approvable, dependent: :destroy }
end
