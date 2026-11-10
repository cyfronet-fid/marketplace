# frozen_string_literal: true

class Api::V1::UserPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      user.admin? ? scope.all : scope.where(uid: user.uid)
    end
  end

  def show?
    if Mp::Variant.pl?
      # pl restricts this endpoint to holders of every role, not just admins.
      user&.roles_mask == User.mask_for(:admin, :coordinator, :executive)
    else
      user.admin? || user.uid == record.uid
    end
  end
end
