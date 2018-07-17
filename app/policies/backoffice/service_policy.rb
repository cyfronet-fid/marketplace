# frozen_string_literal: true

class Backoffice::ServicePolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.where(owner: user)
    end
  end

  def index?
    true
  end

  def show?
    owner?
  end

  def new?
    true
  end

  def create?
    true
  end

  def update?
    owner?
  end

  def destroy?
    owner? && record.orders.count.zero?
  end

  def permitted_attributes
    [:title, :description, :terms_of_use, :tagline, :connected_url, :open_access]
  end

  private

    def owner?
      record.owner == user
    end
end
