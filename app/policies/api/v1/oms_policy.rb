# frozen_string_literal: true

class Api::V1::OMSPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      user.administrated_omses
    end
  end

  def show?
    user.administrated_omses.include? record
  end
end
