# frozen_string_literal: true

class CatalogueVocabulary < ApplicationRecord
  belongs_to :catalogue
  belongs_to :vocabulary, polymorphic: true
  before_create :set_vocabulary_type

  validates :catalogue, presence: true
  validates :vocabulary, presence: true

  def set_vocabulary_type
    self.vocabulary_type = vocabulary.type
  end
end
