# frozen_string_literal: true

class OrderingConfigurationPolicy < ApplicationPolicy
  def show?
    # user&.service_portfolio_manager? ||
    #   user&.service_owner? ||
    record.administered_by?(user)
  end
end
