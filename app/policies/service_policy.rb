# frozen_string_literal: true

class ServicePolicy < ApplicationPolicy
  def show?
    true
  end
end
