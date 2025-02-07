# frozen_string_literal: true

class Api::V1::EssPolicy < ApplicationPolicy
  def index?
    user&.coordinator?
  end

  def show?
    user&.coordinator?
  end
end
