# frozen_string_literal: true

class ServiceOpinionPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(user: user)
    end
  end

  def index?
    user
  end

  def show?
    owner?
  end

  def create?
    user
  end

  def permitted_attributes
    %i[service_rating order_rating opinion]
  end

  private

  def owner?
    record.user == user
  end
end
