# frozen_string_literal: true

class Admin::ApplicationController < ApplicationController
  before_action :authenticate_user!
  before_action :admin_authorization!

  layout "admin"

  def policy_scope(scope)
    super([:admin, scope])
  end

  def authorize(record, query = nil)
    super([:admin, record], query)
  end

  def permitted_attributes(record, action = action_name)
    super([:admin, record], action)
  end

  private

  def admin_authorization!
    authorize :admin, :show?
  end
end
