# frozen_string_literal: true

class HelpSectionPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end
end
