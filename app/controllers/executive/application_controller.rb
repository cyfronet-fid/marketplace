# frozen_string_literal: true

class Executive::ApplicationController < ApplicationController
  before_action :authenticate_user!
  before_action :admin_authorization!

  layout "executive"

  def policy_scope(scope)
    super([:executive, scope])
  end

  def authorize(record, query = nil)
    super([:executive, record], query)
  end

  def permitted_attributes(record, action = action_name)
    super([:executive, record], action)
  end

  private

  def admin_authorization!
    authorize :executive, :show?
  end
end
