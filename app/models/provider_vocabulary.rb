# frozen_string_literal: true

class ProviderVocabulary < ApplicationRecord
  belongs_to :provider
  belongs_to :vocabulary, polymorphic: true
  before_create :set_vocabulary_type

  validates :provider, presence: true
  validates :vocabulary, presence: true

  def set_vocabulary_type
    self.vocabulary_type = vocabulary.type
  end
end
