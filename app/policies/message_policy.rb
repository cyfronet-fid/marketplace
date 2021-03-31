# frozen_string_literal: true

class MessagePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(scope: %w[public user_direct])
    end
  end

  def permitted_attributes
    [:message]
  end
end
