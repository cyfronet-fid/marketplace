# frozen_string_literal: true

class Backoffice::ApplicationController < ApplicationController
  before_action :authenticate_user!
  before_action :backoffice_authorization!

  layout -> { turbo_frame_request? ? "turbo_rails/frame" : "backoffice" }

  def policy_scope(scope)
    super([:backoffice, scope])
  end

  def authorize(record, query = nil)
    super([:backoffice, record], query)
  end

  def permitted_attributes(record, action = action_name)
    super([:backoffice, record], action)
  end

  private

  def backoffice_authorization!
    authorize :backoffice, :show?
  end
end
