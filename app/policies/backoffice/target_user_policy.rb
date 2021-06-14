# frozen_string_literal: true

class Backoffice::TargetUserPolicy < Backoffice::VocabularyPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end
end
