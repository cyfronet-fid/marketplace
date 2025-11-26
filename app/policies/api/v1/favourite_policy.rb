# frozen_string_literal: true

class Api::V1::EssPolicy < ApplicationPolicy
  def permitted_attributes
    %i[pid type name links authors best_access_right]
  end
end
