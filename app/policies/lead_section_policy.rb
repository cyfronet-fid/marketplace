# frozen_string_literal: true

class LeadSectionPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def error?
    user&.admin?
  end
end
