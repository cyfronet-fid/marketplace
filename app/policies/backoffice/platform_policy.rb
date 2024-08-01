# frozen_string_literal: true

class Backoffice::PlatformPolicy < Backoffice::VocabularyPolicy
  def permitted_attributes
    %i[name eid]
  end
end
