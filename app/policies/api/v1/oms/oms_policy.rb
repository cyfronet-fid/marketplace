# frozen_string_literal: true

class Api::V1::Oms::OmsPolicy < ApplicationPolicy
  def this_oms_admin?
    user.administrated_oms.include? record
  end
end
