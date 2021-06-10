# frozen_string_literal: true

class Backoffice::Vocabulary::EsfriTypePolicy < Backoffice::VocabularyPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end
end
