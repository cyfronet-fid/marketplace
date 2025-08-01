# frozen_string_literal: true

class Api::V1::UserPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      user.admin? ? scope.all : scope.where(uid: user.uid)
    end
  end

  def show?
    user.admin? || user.uid == record.uid
  end
end
