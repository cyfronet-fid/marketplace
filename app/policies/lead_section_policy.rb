# frozen_string_literal: true

class LeadSectionPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end
end
