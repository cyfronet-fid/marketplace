# frozen_string_literal: true

class Backoffice::Vocabulary::EntityTypePolicy < Backoffice::VocabularyPolicy
  class Scope < Scope
    def resolve
      scope
    end
  end
end
