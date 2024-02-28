# frozen_string_literal: true

class OfferVocabulary < ApplicationRecord
  belongs_to :offer
  belongs_to :vocabulary, polymorphic: true
  before_create :set_vocabulary_type

  validates :offer, presence: true
  validates :vocabulary, presence: true

  def set_vocabulary_type
    self.vocabulary_type = vocabulary.type
  end
end
