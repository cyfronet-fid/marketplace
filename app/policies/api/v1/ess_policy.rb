# frozen_string_literal: true

class Api::V1::EssPolicy < ApplicationPolicy
  def index?
    user&.service_portfolio_manager?
  end

  def show?
    user&.service_portfolio_manager?
  end
end
