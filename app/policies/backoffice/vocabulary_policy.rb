# frozen_string_literal: true

class Backoffice::VocabularyPolicy < Backoffice::ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end

  def index?
    coordinator?
  end

  def show?
    coordinator?
  end

  def new?
    coordinator?
  end

  def create?
    coordinator?
  end

  def edit?
    coordinator?
  end

  def update?
    coordinator?
  end

  def destroy?
    coordinator?
  end

  def permitted_attributes
    %i[name description eid parent_id logo]
  end
end
