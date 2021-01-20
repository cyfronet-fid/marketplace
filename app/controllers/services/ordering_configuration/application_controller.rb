# frozen_string_literal: true

class Services::OrderingConfiguration::ApplicationController < ApplicationController
  before_action :authenticate_user!

  layout "ordering_configuration"

  def policy_scope(scope)
    super([:ordering_configuration, scope])
  end

  def authorize(record, query = nil)
    super([:ordering_configuration, record], query)
  end

  def permitted_attributes(record, action = action_name)
    super([:ordering_configuration, record], action)
  end
end
