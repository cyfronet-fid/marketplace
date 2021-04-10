# frozen_string_literal: true

class Api::V1::Oms::OmsPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      user.administrated_oms
    end
  end

  def show?
    user.administrated_oms.include? record
  end
end
