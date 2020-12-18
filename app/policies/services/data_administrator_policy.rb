# frozen_string_literal: true

class DataAdministratorPolicy
  def show?
    DataAdministrator.where(email: user&.email).count.positive? ||
      user&.service_portfolio_manager? ||
      user&.service_owner?
  end
end
