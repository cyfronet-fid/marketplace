# frozen_string_literal: true

class ServiceVocabulary < ApplicationRecord
  belongs_to :service
  belongs_to :vocabulary, polymorphic: true
  before_create :set_vocabulary_type

  validates :service, presence: true
  validates :vocabulary, presence: true

  def set_vocabulary_type
    self.vocabulary_type = vocabulary.type
  end
end
