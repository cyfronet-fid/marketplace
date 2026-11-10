# frozen_string_literal: true

class PersistentIdentitySystemVocabulary < ApplicationRecord
  belongs_to :persistent_identity_system
  belongs_to :vocabulary, polymorphic: true
  before_create :set_vocabulary_type

  validates :persistent_identity_system, presence: true
  validates :vocabulary, presence: true

  def set_vocabulary_type
    self.vocabulary_type = vocabulary.type
  end
end
