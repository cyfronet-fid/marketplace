# frozen_string_literal: true

class BundleVocabulary < ApplicationRecord
  belongs_to :bundle
  belongs_to :vocabulary, polymorphic: true
  before_create :set_vocabulary_type

  validates :bundle, presence: true
  validates :vocabulary, presence: true

  def set_vocabulary_type
    self.vocabulary_type = vocabulary.type
  end
end
